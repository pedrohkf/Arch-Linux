from fabric.widgets.box import Box

from window.controlcenter.player import PlayerBoxStack
from window.desktop.registry import DesktopWidgetRegistry


class DesktopPlayerWidget(Box):
    def __init__(self, parent=None, **kwargs):
        super().__init__(
            name="player-desktop-widget",
            h_expand=True,
            v_expand=True,
            visible=True,
            all_visible=True,
            orientation="v",
            **kwargs,
        )
        self.add(PlayerBoxStack())


DesktopWidgetRegistry.register(
    "player", DesktopPlayerWidget, (300, 174), (0.00573, 0.20)
)
