import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)

    // ページがキャッシュから復元された場合、メニューが開いていればリスナーを再登録
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("keydown", this.handleKeydown)
      document.addEventListener("click", this.handleClickOutside)
    }
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleClickOutside)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside)
  }
}
