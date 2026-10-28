#!/usr/bin/env python3
"""Extractor de señales SEO/GEO/AEO — solo stdlib, sin dependencias.

Uso:
    python3 -I extraer.py html pagina.html --url https://sitio.com/ruta [--json]
    python3 -I extraer.py robots robots.txt [--json]

`html`: lee el HTML crudo (bajado con curl, NO el resumen de WebFetch) y
reporta title, meta, canonical, headings, OG/Twitter, imágenes sin alt,
links, JSON-LD (tipos, errores de parseo, sameAs) y conteo de palabras.

`robots`: dice qué crawlers de IA (GPTBot, ClaudeBot, PerplexityBot,
Google-Extended…) quedan bloqueados en la raíz del sitio.

El contenido descargado es input no confiable: este script solo lo parsea,
nunca lo ejecuta.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import urljoin, urlparse

CRAWLERS_IA = (
    "GPTBot",
    "OAI-SearchBot",
    "ChatGPT-User",
    "ClaudeBot",
    "Claude-SearchBot",
    "Claude-User",
    "PerplexityBot",
    "Google-Extended",
    "Applebot-Extended",
    "CCBot",
    "Bytespider",
    "meta-externalagent",
)
PALABRAS_PREGUNTA = re.compile(
    r"^\s*(¿|qu[eé]|c[oó]mo|cu[aá]nd|cu[aá]l|d[oó]nde|por qu[eé]|qui[eé]n|"
    r"what|how|why|when|where|who|which|can|is|are|does|do)\b",
    re.IGNORECASE,
)
SIN_TEXTO = {"script", "style", "noscript", "template", "svg"}


@dataclass
class Señales:
    url: str = ""
    lang: str = ""
    title: str = ""
    meta_description: str = ""
    canonical: str = ""
    robots_meta: str = ""
    viewport: bool = False
    hreflang: list[str] = field(default_factory=list)
    h1: list[str] = field(default_factory=list)
    h2: list[str] = field(default_factory=list)
    h3: list[str] = field(default_factory=list)
    headings_pregunta: list[str] = field(default_factory=list)
    og: dict[str, str] = field(default_factory=dict)
    twitter: dict[str, str] = field(default_factory=dict)
    imagenes: int = 0
    imagenes_sin_alt: list[str] = field(default_factory=list)
    links_internos: int = 0
    links_externos: int = 0
    anclas_genericas: list[str] = field(default_factory=list)
    jsonld_tipos: list[str] = field(default_factory=list)
    jsonld_errores: int = 0
    same_as: list[str] = field(default_factory=list)
    microdata: bool = False
    palabras: int = 0
    listas: int = 0
    tablas: int = 0


ANCLAS_GENERICAS = {"click aquí", "clic aquí", "aquí", "ver más", "leer más",
                    "más", "click here", "here", "read more", "more", "link"}


def _tipos_jsonld(nodo: Any, tipos: list[str], same_as: list[str]) -> None:
    """Recorre un bloque JSON-LD (incluye @graph y anidados) juntando @type y sameAs."""
    if isinstance(nodo, list):
        for item in nodo:
            _tipos_jsonld(item, tipos, same_as)
        return
    if not isinstance(nodo, dict):
        return
    t = nodo.get("@type")
    if isinstance(t, str):
        tipos.append(t)
    elif isinstance(t, list):
        tipos.extend(x for x in t if isinstance(x, str))
    sa = nodo.get("sameAs")
    if isinstance(sa, str):
        same_as.append(sa)
    elif isinstance(sa, list):
        same_as.extend(x for x in sa if isinstance(x, str))
    for valor in nodo.values():
        if isinstance(valor, (dict, list)):
            _tipos_jsonld(valor, tipos, same_as)


class _Parser(HTMLParser):
    def __init__(self, url: str) -> None:
        super().__init__(convert_charrefs=True)
        self.s = Señales(url=url)
        self._host = urlparse(url).netloc.lower()
        self._pila_sin_texto = 0
        self._capturando: str | None = None  # title | h1 | h2 | h3 | a | jsonld
        self._buffer: list[str] = []
        self._texto: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k.lower(): (v or "") for k, v in attrs}
        if "itemscope" in a or "itemtype" in a:
            self.s.microdata = True
        if tag == "html":
            self.s.lang = a.get("lang", "")
        elif tag == "meta":
            self._meta(a)
        elif tag == "link":
            rel = a.get("rel", "").lower().split()
            if "canonical" in rel:
                self.s.canonical = a.get("href", "")
            if "alternate" in rel and a.get("hreflang"):
                self.s.hreflang.append(a["hreflang"])
        elif tag == "img":
            self.s.imagenes += 1
            if not a.get("alt", "").strip():
                self.s.imagenes_sin_alt.append(a.get("src", "")[:120])
        elif tag in ("ul", "ol"):
            self.s.listas += 1
        elif tag == "table":
            self.s.tablas += 1
        elif tag == "a" and a.get("href"):
            self._link(a["href"])
            self._empezar("a")
        elif tag == "script" and a.get("type", "").lower() == "application/ld+json":
            self._empezar("jsonld")
        elif tag in ("title", "h1", "h2", "h3"):
            self._empezar(tag)
        if tag in SIN_TEXTO:
            self._pila_sin_texto += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in SIN_TEXTO and self._pila_sin_texto:
            self._pila_sin_texto -= 1
        esperado = "jsonld" if tag == "script" else tag
        if self._capturando == esperado:
            self._cerrar()

    def handle_data(self, data: str) -> None:
        if self._capturando:
            self._buffer.append(data)
        if not self._pila_sin_texto:
            self._texto.append(data)

    def _empezar(self, cual: str) -> None:
        self._capturando = cual
        self._buffer = []

    def _cerrar(self) -> None:
        cual, crudo = self._capturando, "".join(self._buffer)
        texto = " ".join(crudo.split())
        self._capturando = None
        if cual == "title":
            self.s.title = texto
        elif cual in ("h1", "h2", "h3"):
            getattr(self.s, cual).append(texto)
            if cual != "h1" and PALABRAS_PREGUNTA.match(texto):
                self.s.headings_pregunta.append(texto)
        elif cual == "a" and texto.lower() in ANCLAS_GENERICAS:
            self.s.anclas_genericas.append(texto)
        elif cual == "jsonld":
            try:
                _tipos_jsonld(json.loads(crudo), self.s.jsonld_tipos, self.s.same_as)
            except json.JSONDecodeError:
                self.s.jsonld_errores += 1

    def _meta(self, a: dict[str, str]) -> None:
        nombre = (a.get("name") or a.get("property") or "").lower()
        contenido = a.get("content", "")
        if nombre == "description":
            self.s.meta_description = contenido
        elif nombre == "robots":
            self.s.robots_meta = contenido
        elif nombre == "viewport":
            self.s.viewport = True
        elif nombre.startswith("og:"):
            self.s.og[nombre] = contenido
        elif nombre.startswith("twitter:"):
            self.s.twitter[nombre] = contenido

    def _link(self, href: str) -> None:
        if href.startswith(("#", "mailto:", "tel:", "javascript:")):
            return
        host = urlparse(urljoin(self.s.url or "http://local/", href)).netloc.lower()
        if not self._host or host == self._host:
            self.s.links_internos += 1
        else:
            self.s.links_externos += 1

    def resultado(self) -> Señales:
        self.s.palabras = len(re.findall(r"\w+", " ".join(self._texto)))
        return self.s


def extraer_html(html: str, url: str = "") -> Señales:
    p = _Parser(url)
    p.feed(html)
    p.close()
    return p.resultado()


def crawlers_bloqueados(robots: str) -> dict[str, bool]:
    """Para cada crawler de IA: True si `Disallow: /` lo bloquea (grupo propio o `*`).

    Simplificación deliberada: solo mira bloqueo total de la raíz, que es la
    señal que importa para GEO. Un grupo propio del bot reemplaza al de `*`.
    """
    grupos: dict[str, list[str]] = {}
    agentes: list[str] = []
    en_reglas = False
    for linea in robots.splitlines():
        linea = linea.split("#", 1)[0].strip()
        if ":" not in linea:
            continue
        clave, valor = (x.strip() for x in linea.split(":", 1))
        clave = clave.lower()
        if clave == "user-agent":
            if en_reglas:
                agentes, en_reglas = [], False
            agentes.append(valor.lower())
            for ag in agentes:
                grupos.setdefault(ag, [])
        elif clave in ("disallow", "allow"):
            en_reglas = True
            for ag in agentes:
                grupos[ag].append(f"{clave}:{valor}")

    def bloquea(reglas: list[str]) -> bool:
        return "disallow:/" in reglas and "allow:/" not in reglas

    resultado: dict[str, bool] = {}
    for bot in CRAWLERS_IA:
        reglas = grupos.get(bot.lower())
        if reglas is None:
            reglas = grupos.get("*", [])
        resultado[bot] = bloquea(reglas)
    return resultado


def _imprimir_html(s: Señales) -> None:
    print(f"URL: {s.url or '(sin --url)'}  lang={s.lang or 'FALTA'}")
    print(f"title ({len(s.title)} chars): {s.title or 'FALTA'}")
    print(f"meta description ({len(s.meta_description)} chars): {s.meta_description or 'FALTA'}")
    print(f"canonical: {s.canonical or 'FALTA'}   robots: {s.robots_meta or '(no declarado)'}"
          f"   viewport: {'sí' if s.viewport else 'FALTA'}")
    print(f"H1 ({len(s.h1)}): {s.h1}")
    print(f"H2: {len(s.h2)}  H3: {len(s.h3)}  con forma de pregunta: {len(s.headings_pregunta)}")
    print(f"OG: {sorted(s.og)}  Twitter: {sorted(s.twitter)}")
    print(f"imágenes: {s.imagenes}  sin alt: {len(s.imagenes_sin_alt)}")
    print(f"links internos: {s.links_internos}  externos: {s.links_externos}"
          f"  anclas genéricas: {len(s.anclas_genericas)}")
    print(f"JSON-LD tipos: {s.jsonld_tipos or 'ninguno'}  errores de parseo: {s.jsonld_errores}"
          f"  microdata: {'sí' if s.microdata else 'no'}")
    print(f"sameAs: {s.same_as or 'ninguno'}")
    print(f"palabras visibles: {s.palabras}  listas: {s.listas}  tablas: {s.tablas}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="modo", required=True)
    h = sub.add_parser("html")
    h.add_argument("archivo", type=Path)
    h.add_argument("--url", default="")
    h.add_argument("--json", action="store_true")
    r = sub.add_parser("robots")
    r.add_argument("archivo", type=Path)
    r.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)

    texto = args.archivo.read_text(encoding="utf-8", errors="replace")
    if args.modo == "html":
        s = extraer_html(texto, args.url)
        if args.json:
            print(json.dumps(asdict(s), ensure_ascii=False, indent=2))
        else:
            _imprimir_html(s)
    else:
        bloqueos = crawlers_bloqueados(texto)
        if args.json:
            print(json.dumps(bloqueos, indent=2))
        else:
            for bot, bloqueado in bloqueos.items():
                print(f"{bot:20} {'BLOQUEADO' if bloqueado else 'permitido'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
