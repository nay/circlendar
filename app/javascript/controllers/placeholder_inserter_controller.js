import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "field"]

  insert(event) {
    const select = event.target
    const value = select.value

    if (!value) return

    const field = this.fieldTarget
    const start = field.selectionStart
    const end = field.selectionEnd
    const text = field.value

    field.value = text.substring(0, start) + value + text.substring(end)
    field.selectionStart = field.selectionEnd = start + value.length
    field.focus()

    // Reset select to placeholder option
    select.selectedIndex = 0
  }
}
