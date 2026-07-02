"""Global exception types and FastAPI handler installer."""
import traceback


class MayaError(Exception):
    """Base class for expected application errors."""
    status_code = 400

    def __init__(self, message: str, status_code: int | None = None):
        super().__init__(message)
        if status_code:
            self.status_code = status_code


def install_exception_handler(app, metrics=None) -> None:
    """Attach one JSON handler for MayaError + unexpected exceptions."""
    from fastapi import Request
    from fastapi.responses import JSONResponse

    @app.exception_handler(MayaError)
    async def maya_error_handler(request: Request, exc: MayaError):
        if metrics:
            metrics.incr("errors.expected")
        return JSONResponse(status_code=exc.status_code,
                            content={"error": str(exc), "type": exc.__class__.__name__})

    @app.exception_handler(Exception)
    async def unexpected_handler(request: Request, exc: Exception):
        if metrics:
            metrics.incr("errors.unexpected")
        print("UNEXPECTED ERROR:", "".join(traceback.format_exception(exc))[-2000:])
        return JSONResponse(status_code=500,
                            content={"error": "Internal server error", "type": "InternalError"})
