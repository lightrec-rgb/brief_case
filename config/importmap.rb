# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@rails/ujs",            to: "rails-ujs.js"
# pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
# pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# THIS is what serves /assets/controllers/... from app/javascript/controllers
# pin_all_from "app/javascript/controllers", under: "controllers"
