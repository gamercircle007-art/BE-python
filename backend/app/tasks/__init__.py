"""
Background tasks package.

Ready for Celery, ARQ, or FastAPI BackgroundTasks expansion.
Example: send bulk notifications, generate reports, webhook retries.

MICROSERVICE EXTRACTION: Each domain can publish events to SQS/SNS;
workers consume independently per domain.
"""