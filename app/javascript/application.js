// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

if (window.Turbo && typeof Turbo.setConfirmMethod === "function") {
  Turbo.setConfirmMethod((message, element) => {
    return window.confirm(message);
  });
}

import Rails from "@rails/ujs"
Rails.start()