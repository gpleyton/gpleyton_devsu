import { app, server } from '.'
import request from 'supertest'
import User from './users/model.js'
import sequelize from './shared/database/database'
import { Sequelize } from 'sequelize'

describe('User', () => {
    let data
    let mockedSequelize

    beforeEach(async () => {
        data = {
            "dni": "1234567890",
            "name": "Test"
        }
        jest.spyOn(console, 'log').mockImplementation(jest.fn())
        jest.spyOn(sequelize, 'log').mockImplementation(jest.fn())
        mockedSequelize = new Sequelize({
            database: '<any name>',
            dialect: 'sqlite',
            username: 'root',
            password: '',
            validateOnly: true,
            models: [__dirname + '/models'],
        })
        await mockedSequelize.sync({ force: true })
    })

    afterEach(async () => {
        jest.clearAllMocks()
        await mockedSequelize.close()
    })

    afterAll(async () => {
        server.close()
    })

    test('Get users', async () => {
        jest.spyOn(User, 'findAll').mockResolvedValue([data])
        const response = await request(app).get('/api/users')

        expect(response.status).toBe(200)
        expect(response.body).toEqual([data])
    })

    test('Get user', async () => {
        jest.spyOn(User, 'findByPk').mockResolvedValue({...data, "id": 1})
        const response = await request(app).get('/api/users/1')

        expect(response.status).toBe(200)
        expect(response.body).toEqual({...data, "id": 1})
    })

    test('Create user', async () => {
        jest.spyOn(User, 'findOne').mockResolvedValue(null)
        jest.spyOn(User, 'create').mockResolvedValue({...data, "id": 1})
        const response = await request(app).post('/api/users').send(data)

        expect(response.status).toBe(201)
        expect(response.body).toEqual({...data, "id": 1})
    })
})

describe('Health', () => {
    afterEach(() => {
        jest.clearAllMocks()
    })

    test('Liveness probe returns UP', async () => {
        const response = await request(app).get('/api/health')

        expect(response.status).toBe(200)
        expect(response.body).toEqual({ status: 'UP' })
    })

    test('Readiness probe returns READY when the database is available', async () => {
        jest.spyOn(sequelize, 'authenticate').mockResolvedValue()
        const response = await request(app).get('/api/health/ready')

        expect(response.status).toBe(200)
        expect(response.body).toEqual({ status: 'READY', database: 'UP' })
    })
})
