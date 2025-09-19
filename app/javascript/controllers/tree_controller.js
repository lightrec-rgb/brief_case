import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["branch", "chevron"]

  connect() { console.log("tree_controller connected") }

  toggle(event) {
    const btn = event.currentTarget
    const li = btn.closest("li")
    const branch  = li?.querySelector("[data-tree-target='branch']")
    const chevron = li?.querySelector("[data-tree-target='chevron']")
    if (!branch) return

    branch.classList.toggle("hidden")
    const expanded = !branch.classList.contains("hidden")
    btn.setAttribute("aria-expanded", expanded ? "true" : "false")
    if (chevron) chevron.textContent = expanded ? "▼" : "►"
  }

  expandAll()  { this.branchTargets.forEach((ul) => ul.classList.remove("hidden")); this.chevronTargets.forEach((c) => c.textContent = "▼") }
  collapseAll(){ this.branchTargets.forEach((ul) => ul.classList.add("hidden"));    this.chevronTargets.forEach((c) => c.textContent = "►") }
}