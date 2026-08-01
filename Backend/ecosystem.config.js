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
      env: {
        NODE_ENV: "production",
        PORT: 4000
      }
    }
  ]
};
