## ConfirmPanel — a small modal "are you sure?" box for actions that can't be
## undone (demolish, reset …). Shows a preview text and runs `on_confirm` only
## when the player confirms; Esc or a click outside cancels. Without a callback
## it is an info box with one button.
##   ConfirmPanel.ask(self, "Demolish Alpha?", preview_text, "DEMOLISH", func() -> void: …)
## Look and layout: ModalPopup / PopupCard scenes.
class_name ConfirmPanel
extends RefCounted

static func ask(host: Node, title: String, body: String, confirm_label: String, on_confirm: Callable,
		danger: bool = true) -> ModalPopup:
	var p := ModalPopup.open(host, title, "danger" if danger else "notes", body)
	p.cancel_button().visible = on_confirm.is_valid()
	var ok := p.confirm_button()
	ok.label_text = confirm_label.to_upper()
	ok.variant = IconButton.Variant.NEGATIVE if danger else IconButton.Variant.POSITIVE
	ok.icon_name = "danger" if danger else "confirm"
	ok.pressed.connect(func() -> void:
		p.close()
		if on_confirm.is_valid():
			on_confirm.call())
	return p
