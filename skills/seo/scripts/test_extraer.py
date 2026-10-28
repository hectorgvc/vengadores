"""Tests de extraer.py — correr con: python3 -m unittest test_extraer (desde scripts/)."""
from __future__ import annotations

import unittest

from extraer import crawlers_bloqueados, extraer_html

HTML = """<!doctype html><html lang="es"><head>
<title>Servicios contables en Santo Domingo | Acme</title>
<meta name="description" content="Contabilidad para pymes.">
<meta name="viewport" content="width=device-width">
<meta property="og:title" content="Acme">
<link rel="canonical" href="https://acme.do/servicios">
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
 {"@type":"Organization","name":"Acme","sameAs":["https://instagram.com/acme"]},
 {"@type":["LocalBusiness","AccountingService"]}]}
</script>
<script type="application/ld+json">{roto</script>
<script>var noCuenta = "palabras dentro de script";</script>
</head><body>
<h1>Contabilidad para pymes</h1>
<h2>¿Cuánto cuesta una declaración?</h2><h2>Nuestro equipo</h2>
<img src="a.webp" alt="Oficina"><img src="b.webp">
<a href="/contacto">Contacto</a><a href="https://otro.com">aquí</a><a href="#top">arriba</a>
<ul><li>uno</li></ul>
</body></html>"""


class TestExtraerHtml(unittest.TestCase):
    def setUp(self) -> None:
        self.s = extraer_html(HTML, "https://acme.do/servicios")

    def test_head(self) -> None:
        self.assertEqual(self.s.lang, "es")
        self.assertTrue(self.s.title.startswith("Servicios contables"))
        self.assertEqual(self.s.canonical, "https://acme.do/servicios")
        self.assertTrue(self.s.viewport)
        self.assertIn("og:title", self.s.og)

    def test_jsonld_graph_lista_de_tipos_y_errores(self) -> None:
        self.assertEqual(self.s.jsonld_tipos, ["Organization", "LocalBusiness", "AccountingService"])
        self.assertEqual(self.s.same_as, ["https://instagram.com/acme"])
        self.assertEqual(self.s.jsonld_errores, 1)

    def test_headings_y_preguntas(self) -> None:
        self.assertEqual(self.s.h1, ["Contabilidad para pymes"])
        self.assertEqual(self.s.headings_pregunta, ["¿Cuánto cuesta una declaración?"])

    def test_imagenes_links_y_anclas(self) -> None:
        self.assertEqual((self.s.imagenes, self.s.imagenes_sin_alt), (2, ["b.webp"]))
        self.assertEqual((self.s.links_internos, self.s.links_externos), (1, 1))
        self.assertEqual(self.s.anclas_genericas, ["aquí"])

    def test_texto_de_script_no_cuenta(self) -> None:
        self.assertGreater(self.s.palabras, 0)
        s_sin_script = extraer_html(HTML.replace('var noCuenta = "palabras dentro de script";', ""))
        self.assertEqual(self.s.palabras, s_sin_script.palabras)


class TestCrawlersBloqueados(unittest.TestCase):
    def test_bloqueo_global(self) -> None:
        r = crawlers_bloqueados("User-agent: *\nDisallow: /\n")
        self.assertTrue(all(r.values()))

    def test_grupo_propio_reemplaza_al_comodin(self) -> None:
        robots = "User-agent: *\nDisallow: /\n\nUser-agent: GPTBot\nAllow: /\n"
        r = crawlers_bloqueados(robots)
        self.assertFalse(r["GPTBot"])
        self.assertTrue(r["ClaudeBot"])

    def test_varios_agentes_en_un_grupo_y_comentarios(self) -> None:
        robots = "# ia\nUser-agent: ClaudeBot\nUser-agent: PerplexityBot\nDisallow: / # fuera\n"
        r = crawlers_bloqueados(robots)
        self.assertTrue(r["ClaudeBot"] and r["PerplexityBot"])
        self.assertFalse(r["GPTBot"])

    def test_disallow_vacio_permite(self) -> None:
        self.assertFalse(any(crawlers_bloqueados("User-agent: *\nDisallow:\n").values()))


if __name__ == "__main__":
    unittest.main()
