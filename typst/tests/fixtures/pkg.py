"""A package for tests."""
from dataclasses import dataclass, field


@dataclass(frozen=True)
class Thing:
    """A thing, with **strong** words, `code`, *emphasis*, and a link to [helper][pkg.helper].

    | name | meaning |
    |---|---|
    | `a` | the first |

    Attributes:
        a: The first.
        b: The second, which defaults to an empty list.
    """

    a: int
    b: list = field(default_factory=list)

    def twice(self, factor=2, *, round=False):
        """Twice the thing.

        Args:
            factor (int): How many times.
            round: Whether to round.

        Returns:
            int: The result.
        """

    @property
    def size(self):
        """Its size."""


def helper(x, *args, **kwargs):
    """Help with x.

    - one
    - two
    """
