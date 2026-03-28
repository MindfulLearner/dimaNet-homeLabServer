# AWS Environment Case Study – [Issue #49](https://github.com/MindfulLearner/dima-portfolio/issues/49)

## Overview

This case study documents the build-out of a cloud-based contributor automation system deployed on AWS, the spam/DDoS attack it suffered, and the defensive measures applied in real time.

---

## Project Architecture (Issue #49)

The project is a portfolio site with an automated contributor flow backed by AWS services:

| Component | Role |
|---|---|
| **API Gateway** | Public HTTP endpoint - receives contributor submissions from the frontend |
| **Lambda** | Processes incoming requests, triggers contributor PR creation and README updates |
| **DynamoDB** | Stores contributor records; acts as a validation layer before any action is taken |
| **GitHub Actions** | Handles automatic PR creation, merge, and README updates after Lambda success |
| **CloudWatch** | Real-time log monitoring and alerting across all AWS services |

### Automation Flow

```
User visits portfolio
       ↓
Submits name/email via frontend
       ↓
API Gateway -> Lambda
       ↓
DynamoDB validation check
       ↓
GitHub Actions triggered
       ↓
Auto PR created -> README updated -> Contributor badge added
```

---

## The Attack – [Issue #491](https://github.com/MindfulLearner/dima-portfolio/issues/491) & [Issue #538](https://github.com/MindfulLearner/dima-portfolio/issues/538)

### What happened

The public API endpoint was targeted with crafted payloads sent directly (bypassing the frontend and CORS restrictions). The attacker submitted malformed data including newline-injected strings in the `name` field:

```json
{
  "name": "Hello\nWorld\n\nTest",
  "email": "a@a.com",
  "date": "2023-05-23T17:04:28.293Z"
}
```

This caused the automated Lambda + GitHub Actions pipeline to:
- Create spam issues ([Issue #536](https://github.com/MindfulLearner/dima-portfolio/issues/536), [Issue #537](https://github.com/MindfulLearner/dima-portfolio/issues/537)) with broken/malformed titles
- Flood the repository with junk Auto PRs

The attack vector was possible because:
- The API had no input sanitization on multiline characters
- No rate limiting / throttling was in place at the Gateway level
- No database validation layer was enforcing clean contributor data

### How the attack was identified

CloudWatch logs surfaced the anomalous activity in real time - repeated Lambda invocations with identical malformed payloads from the same source, triggering the PR creation pipeline in rapid succession.

---

## Immediate Response

1. **Deactivated the API** - temporarily disabled the API Gateway endpoint to stop further spam ingestion
2. **Ran cleanup script** - used a GitHub script to bulk-close the spammed PRs created by the attack
3. **Reviewed CloudWatch logs** - confirmed the scope and source of the attack

---

## Defensive Fixes Applied ([Issue #491](https://github.com/MindfulLearner/dima-portfolio/issues/491))

| Fix | Service | Description |
|---|---|---|
| **Input sanitization** | Lambda | Reject payloads containing newline characters or non-printable content in `name`/`email` fields |
| **DynamoDB double-check** | DynamoDB | Validate contributor data against existing records before allowing any pipeline action |
| **API throttling** | API Gateway | Rate limiting enabled to prevent burst abuse from a single source |
| **CloudWatch monitoring** | CloudWatch | Ongoing real-time log protection - alerts on anomalous invocation patterns |

---

## Key Takeaways

- Public APIs must sanitize inputs at the boundary - the frontend enforcing format is not sufficient since attackers bypass it directly
- CloudWatch real-time logging was critical for fast incident detection
- DynamoDB as a validation layer adds a second checkpoint before any automated action runs
- Rate limiting at the Gateway should be enabled from day one on any public endpoint
