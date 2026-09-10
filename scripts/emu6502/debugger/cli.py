from pathlib import Path

from pyapp.app import CliApplication

from emu6502.debugger.gdb import GDBTextInterface

app = CliApplication(application_settings="emu6502.debugger.default_settings")


@app.command
async def target(*, address: str = "::1", port: int = 6502, image_lst: Path | None = None):
    """Run the GDB client."""

    interface = GDBTextInterface(address, port)
    if image_lst:
        interface.load_image(image_lst)
    await interface.run()
