"""
RMQ OUT MSA
"""

import functools

from ftl_python_lib.constants.kubernetes import (ConstantsKubernetes,
                                                 service_url)
from ftl_python_lib.constants.models.mapping import ConstantsMappingSourceType
from ftl_python_lib.core.context.environment import (EnvironmentContext,
                                                     push_environ_to_os)
from ftl_python_lib.core.context.headers import HeadersContext
from ftl_python_lib.core.context.request import RequestContext
from ftl_python_lib.core.log import LOGGER
from ftl_python_lib.core.microservices.api.mapping import (
    MicroserviceApiMapping, MircoserviceApiMappingResponse)
from ftl_python_lib.core.providers.clients.http import ProviderHttpInternal
from ftl_python_lib.core.providers.clients.rabbitmq.rabbitmq import Rabbitmq
from joblib import Parallel, delayed


def _onMessage(chan, method_frame, header_frame, body, thread=1):
    HEADERS_CONTEXT: HeadersContext = HeadersContext({})
    REQUEST_CONTEXT: RequestContext = RequestContext(HEADERS_CONTEXT)
    ENVIRON_CONTEXT: EnvironmentContext = EnvironmentContext()
    """Called when a message is received. Log message and ack it."""
    provider_http_internal: ProviderHttpInternal = ProviderHttpInternal(
        request_context=REQUEST_CONTEXT, environ_context=ENVIRON_CONTEXT
    )

    mapping: MicroserviceApiMapping = MicroserviceApiMapping(
        request_context=REQUEST_CONTEXT, environ_context=ENVIRON_CONTEXT
    )

    transaction_request: dict = provider_http_internal.post(url=service_url(
        service_name="msa-msg-uuid-svc",
        url_prefix="msa/uuid",
    ), headers={}, params={}, data=None
    )

    transaction_id: str = transaction_request.json().get('transaction_id')
    LOGGER.logger.debug(f"Transation-id is {transaction_id}")

    REQUEST_CONTEXT.transaction_id = transaction_id
    mapping_response_microservices: MircoserviceApiMappingResponse = mapping.get(
        params={
            "source": ENVIRON_CONTEXT.rabbitmq_queue,
            "content_type": header_frame.content_type
        }
    )
    for mapping_microservice_item in mapping_response_microservices.data:
        mapping_response: MircoserviceApiMappingResponse = mapping.get(
            params={
                "source": mapping_microservice_item.target,
                "source_type": mapping_microservice_item.source_type,
                "content_type": mapping_microservice_item.content_type,
                "message_type": mapping_microservice_item.message_type
            }
        )
        for mapping_item in mapping_response.data:
            target: str = mapping_item.target

            LOGGER.logger.debug(f"Sending new request to target '{target}'")
            destination = target.split("-")
            result = provider_http_internal.post(url=service_url(
                service_name=f"msa-msg-{destination[3]}-svc",
                url_prefix=f"msa/{destination[3]}",
            ), headers={
                'Content-Type': header_frame.content_type,
                'X-Transaction-Id': transaction_id
            }, params={}, data=body
            )
            LOGGER.logger.debug("The message has been delivered with result:")
            LOGGER.logger.debug(result)
            if result.status_code == 200:
                LOGGER.logger.debug("The message has been delivered")
                chan.basic_ack(delivery_tag=method_frame.delivery_tag)
                LOGGER.logger.debug("The message has been deleted")


def main():
    LOGGER.logger.debug("Proccessing for RMQ OUT microservice")
    push_environ_to_os()
    ENVIRON_CONTEXT: EnvironmentContext = EnvironmentContext()
    Parallel(n_jobs=ENVIRON_CONTEXT.src_parallel_count)(
        delayed(_runInParallel)(thread) for thread in range(ENVIRON_CONTEXT.src_parallel_count))


def _runInParallel(thread=1):
    push_environ_to_os()
    ENVIRON_CONTEXT: EnvironmentContext = EnvironmentContext()
    rabbitmq: Rabbitmq = Rabbitmq(
        rabbitmq_username=ENVIRON_CONTEXT.rabbitmq_username,
        rabbitmq_password=ENVIRON_CONTEXT.rabbitmq_password,
        rabbitmq_endpoint=ENVIRON_CONTEXT.rabbitmq_endpoint,
        rabbitmq_port=ENVIRON_CONTEXT.rabbitmq_port
    )
    rabbitmq_connection = rabbitmq.connection()
    LOGGER.logger.debug("Rabbitmq connection is opened")

    channel = rabbitmq_connection.channel()
    LOGGER.logger.debug(f"Queue is {ENVIRON_CONTEXT.rabbitmq_queue}")
    LOGGER.logger.debug(f"Exchange is {ENVIRON_CONTEXT.rabbitmq_exchange}")
    LOGGER.logger.debug(f"Routing key is {ENVIRON_CONTEXT.rabbitmq_routing_key}")
    channel.queue_bind(
        queue=ENVIRON_CONTEXT.rabbitmq_queue,
        exchange=ENVIRON_CONTEXT.rabbitmq_exchange,
        routing_key=ENVIRON_CONTEXT.rabbitmq_routing_key
    )
    channel.basic_qos(prefetch_count=10)

    on_message_callback = functools.partial(
        _onMessage, thread=thread)
    channel.basic_consume(ENVIRON_CONTEXT.rabbitmq_queue, on_message_callback)

    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()

    rabbitmq_connection.close()
    LOGGER.logger.debug("Rabbitmq connection is closed")


if __name__ == '__main__':
    main()
