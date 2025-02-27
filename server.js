const express = require('express');
const multer = require('multer');
const path = require('path');
const { exec } = require('child_process');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3001;

// Configure multer for handling file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'audio/') // Make sure this directory exists
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname))
    }
});

const upload = multer({ 
    storage: storage,
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('audio/')) {
            cb(null, true);
        } else {
            cb(new Error('Only audio files are allowed!'));
        }
    }
});

// Serve static files from the React app
app.use(express.static(path.join(__dirname, 'build')));

// API endpoint for file upload and transcription
app.post('/api/transcribe', upload.single('audio'), (req, file, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No audio file uploaded' });
    }

    const audioFilePath = req.file.path;
    
    // Run the Ruby script
    exec(`ruby transcribe.rb "${audioFilePath}"`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error}`);
            return res.status(500).json({ error: 'Transcription failed' });
        }

        // Clean up the audio file after processing
        fs.unlink(audioFilePath, (err) => {
            if (err) console.error('Error deleting audio file:', err);
        });

        res.json({ transcription: stdout.trim() });
    });
});

// Catch all other routes and return the React app
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 