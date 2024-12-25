const express = require('express');
const gitRev = require('git-rev');
const gitLastCommit = require('git-last-commit');
const app = express();
const port = 3000;
const pkg = require('./package.json');

let serverStartTime;

app.use(express.static(__dirname));

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

app.get('/actuator/health', (req, res) => {
    res.json({
        "status": "UP"
    });
});

app.get('/actuator/info', (req, res) => {
    gitLastCommit.getLastCommit((err, commit) => {
        if (err) throw err;
        gitRev.branch((branch) => {
            res.json({
                "git": {
                    "branch": branch,
                    "commit": {
                        "id": commit.hash,
                        "time": new Date(commit.committedOn * 1000).toISOString(),
                        "user": {
                            "name": commit.author.name,
                            "email": commit.author.email
                        }
                    }
                },
                "build": {
                    "artifact": pkg.name,
                    "name": pkg.name,
                    "time": new Date(commit.committedOn * 1000).toISOString(),
                    "version": pkg.version,
                }
            });
        });
    });
});

app.get('/actuator/metrics/process.start.time', (req, res) => {
    res.json({
        "name": "process.start.time",
        "description": "The start time of the process",
        "baseUnit": "seconds",
        "measurements": [
            {
                "statistic": "VALUE",
                "value": serverStartTime
            }
        ],
        "availableTags": []
    });
});

app.listen(port, () => {
    serverStartTime = new Date().toISOString();
    console.log(`Server is running at http://localhost:${port}`);
});
