
class ASMError(Exception):
    """Exception raised for errors in the assembly process."""


class ASMValueError(ASMError, ValueError):
    """Exception raised for invalid values in the assembly process."""


class ASMLabelNotFound(ASMError, KeyError):
    """Exception raised when a label is not found."""


class ASMSyntaxError(ASMError, SyntaxError):
    """Exception raised for syntax errors in the assembly process."""
