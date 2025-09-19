import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Auto-register any *_controller.js in this folder
eagerLoadControllersFrom("controllers", application)