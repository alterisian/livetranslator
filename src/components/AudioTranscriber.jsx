import React, { useState } from 'react';
import axios from 'axios';
import './AudioTranscriber.css';

const AudioTranscriber = () => {
    const [file, setFile] = useState(null);
    const [transcription, setTranscription] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    const handleFileChange = (event) => {
        const selectedFile = event.target.files[0];
        if (selectedFile && selectedFile.type.startsWith('audio/')) {
            setFile(selectedFile);
            setError('');
        } else {
            setError('Please select a valid audio file');
            setFile(null);
        }
    };

    const handleSubmit = async (event) => {
        event.preventDefault();
        if (!file) {
            setError('Please select an audio file');
            return;
        }

        setIsLoading(true);
        setError('');

        const formData = new FormData();
        formData.append('audio', file);

        try {
            const response = await axios.post('/api/transcribe', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });
            setTranscription(response.data.transcription);
        } catch (err) {
            setError('Error processing the audio file. Please try again.');
            console.error('Transcription error:', err);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="audio-transcriber">
            <h1>Audio Transcription</h1>
            
            <form onSubmit={handleSubmit} className="upload-form">
                <div className="file-input-container">
                    <input
                        type="file"
                        accept="audio/*"
                        onChange={handleFileChange}
                        className="file-input"
                        id="audio-file"
                    />
                    <label htmlFor="audio-file" className="file-label">
                        {file ? file.name : 'Choose an audio file'}
                    </label>
                </div>

                <button 
                    type="submit" 
                    disabled={!file || isLoading}
                    className="submit-button"
                >
                    {isLoading ? 'Transcribing...' : 'Transcribe Audio'}
                </button>
            </form>

            {error && <div className="error-message">{error}</div>}
            
            {isLoading && (
                <div className="loading-spinner">
                    <div className="spinner"></div>
                    <p>Processing your audio file...</p>
                </div>
            )}

            {transcription && (
                <div className="transcription-result">
                    <h2>Transcription Result:</h2>
                    <div className="transcription-text">
                        {transcription}
                    </div>
                </div>
            )}
        </div>
    );
};

export default AudioTranscriber; 