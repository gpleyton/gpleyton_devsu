import * as express from "express"
import sequelize from "../database/database.js"

const healthRouter = express.Router()

// Liveness probe: reports that the process is running (no external dependencies).
healthRouter.get("/", (req, res) => {
    res.status(200).json({ status: "UP" })
})

// Readiness probe: reports that the app is ready to serve traffic (checks the DB).
healthRouter.get("/ready", async (req, res) => {
    try {
        await sequelize.authenticate()
        res.status(200).json({ status: "READY", database: "UP" })
    } catch (error) {
        res.status(503).json({ status: "NOT_READY", database: "DOWN" })
    }
})

export { healthRouter }
