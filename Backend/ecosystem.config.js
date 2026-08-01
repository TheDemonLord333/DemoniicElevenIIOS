module.exports = {
  apps: [
    {
      name: "demonic-eleven-backend",
      script: "src/server.js",
      cwd: __dirname,
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      // PORT wird bewusst NICHT hier gesetzt, sondern aus Backend/.env gelesen
      // (siehe .env.example) - so muss zum Port-Wechsel nur .env angepasst werden.
      env: {
        NODE_ENV: "production"
      }
    }
  ]
};
