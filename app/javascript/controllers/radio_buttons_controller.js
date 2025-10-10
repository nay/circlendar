import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="radio-buttons"
export default class extends Controller {
  static targets = ["option"]

  connect() {
    // 初期状態で選択されているボタンを設定
    this.updateSelection()
  }

  select(event) {
    this.updateSelection()
  }

  updateSelection() {
    this.optionTargets.forEach((option) => {
      const radio = option.querySelector('input[type="radio"]')
      if (radio.checked) {
        option.classList.remove('border-gray-300', 'bg-white')
        option.classList.add('border-blue-500', 'bg-blue-50')
      } else {
        option.classList.remove('border-blue-500', 'bg-blue-50')
        option.classList.add('border-gray-300', 'bg-white')
      }
    })
  }
}
