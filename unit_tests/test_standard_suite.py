"""Airbyte CDK standard connector tests (spec / check / discover / read contract).

Scenarios come from acceptance-test-config.yml and run against the fake HANA below.
Docker image tests are marked `image_tests` and deselected by default (see pyproject.toml).
"""

import pytest
from airbyte_cdk.test.standard_tests import SourceTestSuiteBase

from source_sap_hana import SourceSapHana


@pytest.fixture(autouse=True)
def seeded_fake_hana(hana):
    hana.add_table(
        "ACDOCA",
        [("RCLNT", "NVARCHAR"), ("BELNR", "NVARCHAR"), ("DOCLN", "NVARCHAR"), ("HSL", "DECIMAL")],
        [("100", "0000000001", "000001", -1.5), ("100", "0000000001", "000002", 1.5)],
        pk=["RCLNT", "BELNR", "DOCLN"],
    )
    hana.add_table("MAKT", [("MATNR", "NVARCHAR"), ("MAKTX", "NVARCHAR")], [("M1", "Libro")])
    return hana


class TestSourceSapHanaStandard(SourceTestSuiteBase):
    connector = SourceSapHana
