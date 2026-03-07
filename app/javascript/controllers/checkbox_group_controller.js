import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-group"
export default class extends Controller {
  static targets = ["checkbox"]

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = true
    })
  }

  deselectAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
    })
  }
}
