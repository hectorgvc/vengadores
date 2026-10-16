"""Tests de perfil.py — correr con: python3 -m unittest test_perfil (desde scripts/)."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from perfil import a_numero, contar_outliers_iqr, perfilar, perfilar_columna


class TestANumero(unittest.TestCase):
    def test_formatos(self) -> None:
        self.assertEqual(a_numero("1,234.50"), 1234.5)
        self.assertEqual(a_numero("1.234,50"), 1234.5)
        self.assertEqual(a_numero("12,5"), 12.5)
        self.assertEqual(a_numero("1,234"), 1234.0)
        self.assertEqual(a_numero("RD$ 500"), 500.0)
        self.assertEqual(a_numero("-3"), -3.0)
        self.assertIsNone(a_numero("abc"))


class TestColumna(unittest.TestCase):
    def test_nulos_fail(self) -> None:
        col = perfilar_columna("x", ["1", "", "", "NULL"])
        self.assertEqual(col.veredicto, "FAIL")
        self.assertAlmostEqual(col.nulos_pct, 0.75)

    def test_fecha(self) -> None:
        col = perfilar_columna("f", ["2026-01-01", "15/03/2026"])
        self.assertEqual((col.tipo, col.minimo, col.maximo), ("fecha", "2026-01-01", "2026-03-15"))

    def test_codigo_con_ceros(self) -> None:
        col = perfilar_columna("rnc", ["001234567", "101234567"])
        self.assertEqual(col.veredicto, "WARN")

    def test_outliers(self) -> None:
        self.assertEqual(contar_outliers_iqr([10, 11, 12, 10, 11, 1000]), 1)


class TestPerfil(unittest.TestCase):
    def _csv(self, contenido: str) -> Path:
        tmp = tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False, encoding="utf-8")
        tmp.write(contenido)
        tmp.close()
        self.addCleanup(Path(tmp.name).unlink)
        return Path(tmp.name)

    def test_ok_con_punto_y_coma(self) -> None:
        p = perfilar(self._csv("id;monto\n1;100\n2;200\n3;150\n"), clave="id")
        self.assertEqual((p.filas, p.columnas, p.veredicto), (3, 2, "OK"))

    def test_duplicados(self) -> None:
        p = perfilar(self._csv("id,monto\n1,100\n1,100\n2,50\n"), clave="id")
        self.assertEqual((p.duplicados_fila, p.duplicados_clave, p.veredicto), (1, 1, "FAIL"))

    def test_clave_inexistente(self) -> None:
        with self.assertRaises(ValueError):
            perfilar(self._csv("a\n1\n"), clave="id")


if __name__ == "__main__":
    unittest.main()
