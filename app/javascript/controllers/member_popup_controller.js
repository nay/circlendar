import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup"]
  static values = {
    name: String,
    organization: String,
    rank: String,
    description: String
  }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  show(event) {
    event.preventDefault()

    // ポップアップの内容を更新
    const content = this.buildContent()
    this.popupTarget.innerHTML = content
    this.popupTarget.classList.remove("hidden")

    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleClickOutside)
  }

  hide() {
    this.popupTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  buildContent() {
    let html = `<div class="font-medium text-gray-900 mb-2">${this.escapeHtml(this.nameValue)}</div>`

    const details = []
    if (this.organizationValue) {
      details.push(this.escapeHtml(this.organizationValue))
    }
    if (this.rankValue) {
      details.push(this.escapeHtml(this.rankValue))
    }

    if (details.length > 0) {
      html += `<div class="text-sm text-gray-600 mb-2">${details.join(" / ")}</div>`
    }

    if (this.descriptionValue) {
      html += `<div class="text-sm text-gray-500 whitespace-pre-wrap">${this.escapeHtml(this.descriptionValue)}</div>`
    }

    return html
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside)
  }
}
