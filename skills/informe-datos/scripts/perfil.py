#!/usr/bin/env python3
"""Perfilador de calidad para CSV — solo stdlib, sin dependencias.

Uso:
    python3 -I perfil.py datos.csv [--clave COL] [--sep ;] [--json]

Reporta por columna: tipo inferido, % nulos, distintos, min/max/media/mediana,
outliers (IQR) y rango de fechas, con veredicto OK/WARN/FAIL según los
umbrales de references/calidad-datos.md. Código de salida 1 si hay algún FAIL.
"""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys
from dataclasses import asdict, dataclass, field
from datetime import date, datetime
from pathlib import Path

NULOS = {"", "null", "none", "nan", "n/a", "na", "-"}
NULOS_WARN = 0.05
NULOS_FAIL = 0.30
DUP_FAIL = 0.01
FORMATOS_FECHA = ("%Y-%m-%d", "%Y-%m-%d %H:%M:%S", "%d/%m/%Y", "%d/%m/%Y %H:%M", "%d-%m-%Y")


@dataclass
class PerfilColumna:
    nombre: str
    tipo: str
    nulos_pct: float
    distintos: int
    minimo: str | None = None
    maximo: str | None = None
    media: float | None = None
    mediana: float | None = None
    outliers: int = 0
    veredicto: str = "OK"
    notas: list[str] = field(default_factory=list)


@dataclass
class Perfil:
    archivo: str
    filas: int
    columnas: int
    duplicados_fila: int
    duplicados_clave: int | None
    veredicto: str
    columnas_detalle: list[PerfilColumna]


def es_nulo(valor: str) -> bool:
    return valor.strip().lower() in NULOS


def a_numero(valor: str) -> float | None:
    """Convierte '1,234.50', '1.234,50', 'RD$ 500' o '-3' a float; None si no es número."""
    v = valor.strip().replace("RD$", "").replace("US$", "").replace("$", "").replace(" ", "")
    if not v:
        return None
    if "," in v and "." in v:
        # El separador que aparece último es el decimal.
        v = v.replace(".", "").replace(",", ".") if v.rfind(",") > v.rfind(".") else v.replace(",", "")
    elif "," in v:
        partes = v.split(",")
        # "1,234" (miles) vs "12,5" (decimal)
        v = v.replace(",", "") if len(partes[-1]) == 3 and len(partes) > 1 else v.replace(",", ".")
    try:
        return float(v)
    except ValueError:
        return None


def a_fecha(valor: str) -> date | None:
    v = valor.strip()
    for fmt in FORMATOS_FECHA:
        try:
            return datetime.strptime(v, fmt).date()
        except ValueError:
            continue
    return None


def contar_outliers_iqr(numeros: list[float]) -> int:
    if len(numeros) < 4:
        return 0
    q1, _, q3 = statistics.quantiles(numeros, n=4)
    iqr = q3 - q1
    bajo, alto = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    return sum(1 for n in numeros if n < bajo or n > alto)


def perfilar_columna(nombre: str, valores: list[str]) -> PerfilColumna:
    total = len(valores)
    presentes = [v for v in valores if not es_nulo(v)]
    nulos_pct = (total - len(presentes)) / total if total else 0.0
    col = PerfilColumna(nombre=nombre, tipo="vacía", nulos_pct=round(nulos_pct, 4),
                        distintos=len(set(presentes)))

    if presentes:
        numeros = [n for n in (a_numero(v) for v in presentes) if n is not None]
        fechas = [f for f in (a_fecha(v) for v in presentes) if f is not None]
        if len(fechas) == len(presentes):
            col.tipo = "fecha"
            col.minimo, col.maximo = min(fechas).isoformat(), max(fechas).isoformat()
            if max(fechas) > date.today():
                col.notas.append("hay fechas futuras")
        elif len(numeros) == len(presentes):
            col.tipo = "número"
            col.minimo, col.maximo = str(min(numeros)), str(max(numeros))
            col.media = round(statistics.fmean(numeros), 4)
            col.mediana = round(statistics.median(numeros), 4)
            col.outliers = contar_outliers_iqr(numeros)
            if col.outliers:
                col.notas.append(f"{col.outliers} outliers IQR: revisar (señal real / error / centinela)")
            if any(n < 0 for n in numeros):
                col.notas.append("hay valores negativos")
            if any(v.strip().startswith("0") and len(v.strip()) > 1 and "." not in v and "," not in v
                   for v in presentes):
                col.notas.append("ceros a la izquierda: ¿es un código (RNC, cédula) y no un número?")
        else:
            col.tipo = "texto"
            if len(numeros) > len(presentes) * 0.8:
                col.notas.append("mayormente numérica con valores no numéricos mezclados")

    if nulos_pct > NULOS_FAIL:
        col.veredicto = "FAIL"
    elif nulos_pct > NULOS_WARN or col.notas:
        col.veredicto = "WARN"
    return col


def detectar_separador(muestra: str) -> str:
    try:
        return csv.Sniffer().sniff(muestra, delimiters=",;\t|").delimiter
    except csv.Error:
        return ","


def leer_csv(ruta: Path, sep: str | None) -> tuple[list[str], list[list[str]]]:
    for encoding in ("utf-8-sig", "latin-1"):
        try:
            texto = ruta.read_text(encoding=encoding)
            break
        except UnicodeDecodeError:
            continue
    delimitador = sep or detectar_separador(texto[:8192])
    filas = list(csv.reader(texto.splitlines(), delimiter=delimitador))
    if not filas:
        raise ValueError(f"{ruta} está vacío")
    return filas[0], [f for f in filas[1:] if any(c.strip() for c in f)]


def perfilar(ruta: Path, clave: str | None = None, sep: str | None = None) -> Perfil:
    encabezado, filas = leer_csv(ruta, sep)
    columnas = [[f[i] if i < len(f) else "" for f in filas] for i in range(len(encabezado))]
    detalle = [perfilar_columna(n, c) for n, c in zip(encabezado, columnas)]

    duplicados_fila = len(filas) - len({tuple(f) for f in filas})
    duplicados_clave: int | None = None
    if clave is not None:
        if clave not in encabezado:
            raise ValueError(f"la columna clave '{clave}' no existe; columnas: {encabezado}")
        valores_clave = columnas[encabezado.index(clave)]
        duplicados_clave = len(valores_clave) - len(set(valores_clave))

    veredicto = "OK"
    if any(c.veredicto == "WARN" for c in detalle) or duplicados_fila or duplicados_clave:
        veredicto = "WARN"
    if (any(c.veredicto == "FAIL" for c in detalle)
            or (filas and duplicados_fila / len(filas) > DUP_FAIL)):
        veredicto = "FAIL"

    return Perfil(archivo=str(ruta), filas=len(filas), columnas=len(encabezado),
                  duplicados_fila=duplicados_fila, duplicados_clave=duplicados_clave,
                  veredicto=veredicto, columnas_detalle=detalle)


def formatear(perfil: Perfil) -> str:
    lineas = [
        f"Archivo: {perfil.archivo}",
        f"Filas: {perfil.filas} · Columnas: {perfil.columnas} · "
        f"Duplicados fila: {perfil.duplicados_fila}"
        + (f" · Duplicados clave: {perfil.duplicados_clave}" if perfil.duplicados_clave is not None else ""),
        f"Veredicto: {perfil.veredicto}",
        "",
        f"{'columna':<24} {'tipo':<7} {'nulos%':>7} {'distint':>8}  {'min':<12} {'max':<12} veredicto",
    ]
    for c in perfil.columnas_detalle:
        lineas.append(f"{c.nombre[:24]:<24} {c.tipo:<7} {c.nulos_pct * 100:>6.1f}% {c.distintos:>8}  "
                      f"{(c.minimo or '')[:12]:<12} {(c.maximo or '')[:12]:<12} {c.veredicto}")
        lineas.extend(f"    - {n}" for n in c.notas)
    return "\n".join(lineas)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("archivo", type=Path)
    parser.add_argument("--clave", help="columna que debería ser única")
    parser.add_argument("--sep", help="separador (por defecto se detecta)")
    parser.add_argument("--json", action="store_true", help="salida JSON")
    args = parser.parse_args(argv)

    perfil = perfilar(args.archivo, args.clave, args.sep)
    if args.json:
        print(json.dumps(asdict(perfil), ensure_ascii=False, indent=2))
    else:
        print(formatear(perfil))
    return 1 if perfil.veredicto == "FAIL" else 0


if __name__ == "__main__":
    sys.exit(main())
