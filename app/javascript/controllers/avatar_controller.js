import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar"
export default class extends Controller {
  static values = {
    one: String,
    two: String,
    three: String,
    four: String,
    five: String,
  }
  static targets = ["image"]

  change(event) {
    const selected = event.currentTarget.value
    switch (selected) {
      case "Avatar-1":
        this.imageTarget.src = this.oneValue
        break;
      case "Avatar-2":
        this.imageTarget.src = this.twoValue
        break;
      case "Avatar-3":
        this.imageTarget.src = this.threeValue
        break;
      case "Avatar-4":
        this.imageTarget.src = this.fourValue
        break;
      case "Avatar-5":
        this.imageTarget.src = this.fiveValue
        break;

      default:
        this.imageTarget.src = this.oneValue
        break;
    }

  }
}
