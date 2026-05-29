import * as express from "express"
import sequelize from "../database/database.js"

const healthRouter = express.Router()

// Liveness probe: indica que el proceso está vivo (no toca dependencias externas).
healthRouter.get("/", (req, res) => {
    res.status(200).json({ status: "UP" })
})

// Readiness probe: indica que la app está lista para recibir tráfico (verifica la BD).
healthRouter.get("/ready", async (req, res) => {
    try {
        await sequelize.authenticate()
        res.status(200).json({ status: "READY", database: "UP" })
    } catch (error) {
        res.status(503).json({ status: "NOT_READY", database: "DOWN" })
    }
})

export { healthRouter }
