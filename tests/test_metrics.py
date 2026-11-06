"""Tests for the placeholder package rendered by autodoc."""

import pytest

from my_awesome_machine_learning_package import (
    mean_absolute_error,
    regression_report,
)


def test_mean_absolute_error() -> None:
    """Verify the mean absolute error of simple predictions."""
    assert mean_absolute_error([1.0, 2.0, 4.0], [1.0, 3.0, 2.0]) == pytest.approx(1.0)


def test_regression_report() -> None:
    """Verify the report combines count, MAE, and RMSE."""
    report = regression_report([2.0, 4.0], [0.0, 4.0])

    assert report.sample_count == 2
    assert report.mean_absolute_error == pytest.approx(1.0)
    assert report.root_mean_squared_error == pytest.approx(2**0.5)


@pytest.mark.parametrize(
    ("predictions", "targets"),
    [([], []), ([1.0], [1.0, 2.0])],
)
def test_invalid_inputs_are_rejected(
    predictions: list[float], targets: list[float]
) -> None:
    """Verify empty or mismatched inputs raise ValueError."""
    with pytest.raises(ValueError):
        regression_report(predictions, targets)
