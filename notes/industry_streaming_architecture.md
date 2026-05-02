# Industry-Level Real-Time Data Streaming Architecture

This document serves as a comprehensive guide to implementing a seamless, "industry-level" real-time streaming pipeline across the AM Portfolio ecosystem. 

## 1. Core Concepts: The "Why" and "What"

### What is Streaming?
Traditional applications use a **Pull (REST)** model: The UI asks the server "Are there new trades?" every 5 seconds. This is laggy and wastes battery/bandwidth.
Streaming uses a **Push** model: The server keeps a persistent connection open and pushes data instantly the millisecond it changes.

### The Technologies
1. **WebSockets:** The physical, bi-directional "wire" between the Flutter app and the Gateway.
2. **STOMP (Simple Text Oriented Messaging Protocol):** The "language" spoken over the WebSocket. It provides "Topics" so the UI can say "I only want messages addressed to `/topic/trades`".
3. **Kafka:** The high-speed internal message bus that backend services use to communicate securely without knowing about each other.

---

## 2. The 3-Tier Architecture

To achieve a seamless experience, we do **not** connect the UI directly to the Database service. We use a 3-tier bridge:

1. **`am-trade-management` (The Source):** Handles business logic, saves to DB, and broadcasts "Events" to Kafka.
2. **`am-gateway` inside `am-core-services` (The Bridge):** Listens to Kafka, manages WebSocket security, and translates internal Kafka events into STOMP messages for the UI.
3. **`am-modern-ui` (The Consumer):** Connects to the Gateway, listens to specific topics, and updates the screen reactively.

---

## 3. Implementation Details by Repository

### A. `am-trade-management` (Backend Logic)
**Role:** To broadcast state changes the moment they happen.

**1. Create the Producer (`am-trade-kafka/src/main/java/am/trade/kafka/producer/TradeKafkaProducer.java`)**
```java
@Service
@RequiredArgsConstructor
public class TradeKafkaProducer {
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    public void sendTradeEvent(TradeDTO trade, String action) {
        TradeEvent event = new TradeEvent(action, trade); // action = CREATE/UPDATE
        kafkaTemplate.send("trade-events", trade.getUserId(), event);
    }
}
```

**2. Hook into Business Logic (`am-trade-services/.../TradeServiceImpl.java`)**
```java
public TradeDTO createTrade(TradeDTO tradeDTO) {
    Trade savedTrade = tradeRepository.save(trade);
    TradeDTO result = tradeMapper.toDto(savedTrade);
    
    // Broadcast the event immediately after successful DB save
    tradeKafkaProducer.sendTradeEvent(result, "CREATE"); 
    return result;
}
```

**3. Industry Level Configurations (`KafkaConfig.java`)**
To ensure financial data is never lost or duplicated:
```java
// Guaranteed Delivery (Must wait for all backup servers to acknowledge)
props.put(ProducerConfig.ACKS_CONFIG, "all"); 

// Exactly-Once Semantics (Prevents duplicate messages if network blips)
props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true); 

// Resilience (Retry on failure)
props.put(ProducerConfig.RETRIES_CONFIG, Integer.MAX_VALUE);
```

---

### B. `am-core-services` -> `am-gateway` (The Bridge)
**Role:** Security, Connection Management, and Routing.

**1. Configure STOMP & WebSockets (`WebSocketConfig.java`)**
```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Enable User Destinations for private, secure streaming
        config.enableSimpleBroker("/topic", "/queue", "/user"); 
        config.setUserDestinationPrefix("/user"); 
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws-gateway").withSockJS();
    }
}
```

**2. The Kafka-to-WebSocket Bridge (`GatewayKafkaListener.java`)**
```java
@KafkaListener(topics = "trade-events")
public void handleTradeUpdate(TradeEvent event) {
    String userId = event.getData().getUserId(); 
    
    // Spring secures this so ONLY the user with 'userId' receives it
    messagingTemplate.convertAndSendToUser(
        userId, 
        "/topic/trades", 
        event
    );
}
```

**3. The Security Interceptor (`ChannelInterceptor` / `StompPrincipal.java`)**
*Required to read the JWT token during the WebSocket handshake and assign a `Principal` (identity) to the session. This is how `convertAndSendToUser` knows who is who.*

---

### C. `am-modern-ui` (Frontend)
**Role:** Connect, Subscribe, and React.

**1. The Client (`am_stomp_client.dart`)**
Handles the connection and auto-reconnection (Exponential Backoff).

**2. Subscribing to Private Data (`websocket_cubit.dart`)**
```dart
stompClient.subscribe(
  // The "/user/" prefix guarantees we only get OUR trades
  destination: '/user/topic/trades', 
  callback: (frame) {
    var event = jsonDecode(frame.body!);
    if (event['action'] == 'CREATE') {
      emit(TradeAddedState(event['data']));
    }
  }
);
```

**3. Reactive UI (`InstrumentCard.dart` or `TradeList.dart`)**
Use `BlocBuilder` to listen to the Cubit state. When a new state arrives, the UI updates instantly without a full page refresh.

---

## 4. Characteristics of an "Industry Level" Setup

If you build the above, you are 90% there. The final 10% involves:

1. **Schema Registry (Avro/Protobuf):** Instead of raw JSON, define a strict schema. If a backend developer changes `userId` to `user_id`, the build fails before it crashes the UI.
2. **Kafka Partitioning:** Splitting the `trade-events` topic into multiple partitions so multiple instances of `am-gateway` can process messages in parallel (Scalability).
3. **Dead Letter Queues (DLQ):** If the Gateway cannot parse a Kafka message, it shouldn't crash. It should move the bad message to a DLQ topic for manual inspection.
4. **Data Compression:** Using `snappy` or `gzip` compression over WebSockets to save mobile bandwidth.
