const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const axios = require('axios');

const app = express();

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Set up EJS as the templating engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Render Home Page
app.get('/', (req, res) => {
    res.render('index');
});

// Render Form Page
app.get('/form', (req, res) => {
    res.render('form', { error: null, success: null });
});

// Handle Form Submission (POST to Flask backend)
app.post('/submit', async (req, res) => {
    const { name, email } = req.body;
    if (!name || !email) {
        return res.render('form', { error: 'All fields are required', success: null });
    }
    try {
        // Flask backend URL - set FLASK_URL env var in ECS task definition
        const flaskUrl = "http://localhost:5000/process";
        console.log('flaskURL:', flaskUrl,'/n');
        const response = await axios.post(flaskUrl, { name, email });
        console.log('Flask response:', response.data);
        if (response.data && response.data.success) {
            res.render('form', { error: null, success: response.data.message });
        } else {
            res.render('form', { error: 'Submission failed.', success: null });
        }
    } catch (error) {
        console.log('Error:', error.response ? error.response.data : error.message);
        res.render('form', { error: 'Error connecting to backend: ' + error.message, success: null });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT,"0.0.0.0", () => {
    console.log(`Frontend server running on http://localhost:${PORT}`);
});
