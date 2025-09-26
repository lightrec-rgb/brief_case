import "@hotwired/turbo-rails"

if (window.Turbo && typeof Turbo.setConfirmMethod === "function") {
  Turbo.setConfirmMethod((message, element) => window.confirm(message));
}

import Rails from "@rails/ujs"
Rails.start()