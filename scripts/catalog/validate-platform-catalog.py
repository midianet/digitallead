#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = (
    REPOSITORY_ROOT
    / "platform/catalog/schemas/platform-service-v1.schema.json"
)
DEFAULT_SERVICES_DIR = REPOSITORY_ROOT / "platform/catalog/services"


def load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        raise RuntimeError(f"Arquivo não encontrado: {path}") from None
    except json.JSONDecodeError as error:
        raise RuntimeError(
            f"JSON inválido em {path}: linha {error.lineno}, "
            f"coluna {error.colno}: {error.msg}"
        ) from error


def load_yaml(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as file:
            document = yaml.safe_load(file)
    except FileNotFoundError:
        raise RuntimeError(f"Arquivo não encontrado: {path}") from None
    except yaml.YAMLError as error:
        raise RuntimeError(f"YAML inválido em {path}: {error}") from error

    if not isinstance(document, dict):
        raise RuntimeError(
            f"O documento {path} deve possuir um objeto YAML na raiz."
        )

    return document


def format_json_path(path_parts: list[Any]) -> str:
    if not path_parts:
        return "$"

    result = "$"

    for part in path_parts:
        if isinstance(part, int):
            result += f"[{part}]"
        else:
            result += f".{part}"

    return result


def validate_schema(
    validator: Draft202012Validator,
    file_path: Path,
    document: dict[str, Any],
) -> list[str]:
    errors: list[str] = []

    sorted_errors = sorted(
        validator.iter_errors(document),
        key=lambda error: list(error.absolute_path),
    )

    for error in sorted_errors:
        json_path = format_json_path(list(error.absolute_path))
        errors.append(f"{file_path}: {json_path}: {error.message}")

    return errors


def validate_consistency(
    file_path: Path,
    document: dict[str, Any],
) -> list[str]:
    errors: list[str] = []

    metadata = document["metadata"]
    spec = document["spec"]

    ingress = spec["network"]["ingress"]
    storage = spec["storage"]
    backup = spec["backup"]
    deployment = spec["deployment"]
    documentation = spec["documentation"]

    if ingress["enabled"]:
        if not ingress["hostname"]:
            errors.append(
                f"{file_path}: ingress habilitado exige hostname."
            )

        if not ingress["tls"]:
            errors.append(
                f"{file_path}: ingress público deve utilizar TLS."
            )
    else:
        if ingress["hostname"] is not None:
            errors.append(
                f"{file_path}: ingress desabilitado deve possuir hostname null."
            )

    if storage["persistent"]:
        required_storage_fields = (
            "storageClass",
            "requestedSize",
            "reclaimPolicy",
        )

        for field_name in required_storage_fields:
            if storage[field_name] is None:
                errors.append(
                    f"{file_path}: storage persistente exige "
                    f"spec.storage.{field_name}."
                )
    else:
        for field_name in (
            "storageClass",
            "requestedSize",
            "reclaimPolicy",
            "physicalPath",
        ):
            if storage[field_name] is not None:
                errors.append(
                    f"{file_path}: storage não persistente deve possuir "
                    f"spec.storage.{field_name}=null."
                )

    if backup["required"]:
        if not backup["method"]:
            errors.append(
                f"{file_path}: backup obrigatório exige método definido."
            )

        if not backup["restoreProcedure"]:
            errors.append(
                f"{file_path}: backup obrigatório exige procedimento "
                "de restauração."
            )

    if backup["enabled"] and not backup["required"]:
        errors.append(
            f"{file_path}: backup habilitado deve possuir required=true."
        )

    configuration_path = deployment.get("configurationPath")

    if configuration_path:
        absolute_configuration_path = REPOSITORY_ROOT / configuration_path

        if not absolute_configuration_path.exists():
            errors.append(
                f"{file_path}: configurationPath não existe: "
                f"{configuration_path}"
            )

    for documentation_type, documentation_path in documentation.items():
        if not documentation_path:
            continue

        absolute_documentation_path = REPOSITORY_ROOT / documentation_path

        if not absolute_documentation_path.exists():
            errors.append(
                f"{file_path}: caminho de documentação '{documentation_type}' "
                f"não existe: {documentation_path}"
            )

    if metadata["id"].startswith("APP-") and spec["tier"] != "application":
        errors.append(
            f"{file_path}: IDs APP-* devem usar tier=application."
        )

    if metadata["id"].startswith("PLT-") and spec["tier"] == "application":
        errors.append(
            f"{file_path}: IDs PLT-* não devem usar tier=application."
        )

    external_ports = [
        port
        for port in spec["network"]["ports"]
        if port["exposure"] == "external"
    ]

    if external_ports and not ingress["enabled"]:
        errors.append(
            f"{file_path}: existem portas externas, mas o ingress está "
            "desabilitado."
        )

    return errors


def validate_duplicates(
    documents: list[tuple[Path, dict[str, Any]]],
) -> list[str]:
    errors: list[str] = []
    identifiers: dict[str, Path] = {}
    names: dict[str, Path] = {}
    risk_ids: dict[str, Path] = {}

    for file_path, document in documents:
        metadata = document["metadata"]

        service_id = metadata["id"]
        service_name = metadata["name"]

        if service_id in identifiers:
            errors.append(
                f"{file_path}: ID duplicado '{service_id}', já utilizado em "
                f"{identifiers[service_id]}."
            )
        else:
            identifiers[service_id] = file_path

        if service_name in names:
            errors.append(
                f"{file_path}: nome duplicado '{service_name}', já utilizado "
                f"em {names[service_name]}."
            )
        else:
            names[service_name] = file_path

        for risk in document["spec"]["risks"]:
            risk_id = risk["id"]

            if risk_id in risk_ids:
                errors.append(
                    f"{file_path}: risco duplicado '{risk_id}', já utilizado "
                    f"em {risk_ids[risk_id]}."
                )
            else:
                risk_ids[risk_id] = file_path

    return errors


def validate_dependency_references(
    documents: list[tuple[Path, dict[str, Any]]],
) -> list[str]:
    errors: list[str] = []

    known_ids = {
        document["metadata"]["id"]
        for _, document in documents
    }

    for file_path, document in documents:
        for dependency in document["spec"]["dependencies"]:
            dependency_id = dependency["id"]

            # Durante a implantação inicial ainda existem componentes
            # documentados que não possuem PSD próprio. Esses IDs são
            # reportados apenas como aviso.
            if dependency_id not in known_ids:
                print(
                    f"AVISO: {file_path}: dependência {dependency_id} "
                    "ainda não possui definição no catálogo.",
                    file=sys.stderr,
                )

    return errors


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Valida o catálogo da Plataforma Digitalead."
    )

    parser.add_argument(
        "--schema",
        type=Path,
        default=DEFAULT_SCHEMA,
        help="Caminho do JSON Schema.",
    )

    parser.add_argument(
        "--services-dir",
        type=Path,
        default=DEFAULT_SERVICES_DIR,
        help="Diretório contendo os PlatformService YAMLs.",
    )

    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()

    try:
        schema = load_json(arguments.schema)
    except RuntimeError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1

    validator = Draft202012Validator(schema)

    service_files = sorted(arguments.services_dir.glob("*.yaml"))

    if not service_files:
        print(
            f"ERRO: nenhum serviço encontrado em "
            f"{arguments.services_dir}.",
            file=sys.stderr,
        )
        return 1

    documents: list[tuple[Path, dict[str, Any]]] = []
    errors: list[str] = []

    for service_file in service_files:
        try:
            document = load_yaml(service_file)
        except RuntimeError as error:
            errors.append(str(error))
            continue

        schema_errors = validate_schema(
            validator,
            service_file,
            document,
        )

        errors.extend(schema_errors)

        if not schema_errors:
            errors.extend(
                validate_consistency(service_file, document)
            )
            documents.append((service_file, document))

    errors.extend(validate_duplicates(documents))
    errors.extend(validate_dependency_references(documents))

    if errors:
        print("Catálogo inválido:\n", file=sys.stderr)

        for error in errors:
            print(f"- {error}", file=sys.stderr)

        print(
            f"\nTotal de erros: {len(errors)}",
            file=sys.stderr,
        )

        return 1

    print(
        f"Catálogo válido: {len(documents)} serviço(s) analisado(s)."
    )

    for service_file, document in documents:
        print(
            f"- {document['metadata']['id']} "
            f"{document['metadata']['name']} "
            f"({service_file.relative_to(REPOSITORY_ROOT)})"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
