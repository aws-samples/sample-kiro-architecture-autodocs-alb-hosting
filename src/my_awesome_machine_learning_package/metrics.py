"""Regression metrics used to demonstrate Sphinx autodoc."""

from collections.abc import Sequence
from dataclasses import dataclass
import math


@dataclass(frozen=True)
class RegressionReport:
    """Summary metrics for a set of regression predictions.

    Attributes:
        sample_count: Number of prediction and target pairs.
        mean_absolute_error: Mean of the absolute prediction errors.
        root_mean_squared_error: Square root of the mean squared error.
    """

    sample_count: int
    mean_absolute_error: float
    root_mean_squared_error: float


def _validate_pairs(predictions: Sequence[float], targets: Sequence[float]) -> None:
    if len(predictions) != len(targets):
        raise ValueError("predictions and targets must have the same length")
    if not predictions:
        raise ValueError("predictions and targets must not be empty")


def mean_absolute_error(predictions: Sequence[float], targets: Sequence[float]) -> float:
    """Calculate the mean absolute error.

    Args:
        predictions: Predicted values.
        targets: Observed values in the same order as ``predictions``.

    Returns:
        The mean of the absolute differences between predictions and targets.

    Raises:
        ValueError: If the inputs are empty or have different lengths.
    """
    _validate_pairs(predictions, targets)
    return sum(abs(p - t) for p, t in zip(predictions, targets)) / len(predictions)


def regression_report(
    predictions: Sequence[float], targets: Sequence[float]
) -> RegressionReport:
    """Summarize regression predictions.

    Args:
        predictions: Predicted values.
        targets: Observed values in the same order as ``predictions``.

    Returns:
        The sample count, mean absolute error, and root mean squared error.

    Raises:
        ValueError: If the inputs are empty or have different lengths.
    """
    _validate_pairs(predictions, targets)
    squared = sum((p - t) ** 2 for p, t in zip(predictions, targets))
    return RegressionReport(
        sample_count=len(predictions),
        mean_absolute_error=mean_absolute_error(predictions, targets),
        root_mean_squared_error=math.sqrt(squared / len(predictions)),
    )
