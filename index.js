const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const app = express();

// SABOTAGE 1: Expects a very specific environment variable name!
const dbUri = process.env.DATABASE_URI || 'mongodb://localhost:27017/phoenix';

mongoose.connect(dbUri)
  .then(() => console.log('Connected to MongoDB!'))
  .catch(err => console.error('Failed to connect:', err));

// SABOTAGE 2: Express is looking for a 'public' folder, but Vite builds to 'dist'!
const uiPath = path.join(__dirname, 'public'); 
app.use(express.static(uiPath));

app.get('/api/health', (req, res) => res.json({ status: 'API is alive' }));

app.listen(5000, () => console.log('Server running on port 5000'));