import           Protolude
import qualified Kafka.Types                   as KT
import qualified Kafka.Consumer                as KC

main :: IO ()
main = bracket (KC.newConsumer (KC.brokersList [brokerAddress]
                                 <> KC.groupId subscribeGroupId
                                 <> KC.noAutoCommit
                                 <> KC.logLevel KC.KafkaLogInfo)
                               (KC.topics [subscribeTopicName]))
               (\case
                 Left _ -> pure ()
                 Right kafka -> processMessages kafka)
               (\case
                 Left  _err -> pure ()
                 Right kafka -> KC.closeConsumer kafka >> pure ())
 where
  brokerAddress = KT.BrokerAddress "localhost:9092"
  subscribeGroupId = KC.ConsumerGroupId "subscribe"
  subscribeTopicName = KT.TopicName "subscribe-topic"
  timeout = KT.Timeout 1000
  processMessages kafka =
    mapM_ (\_ -> do
                    _msg1 <- KC.pollMessage kafka timeout
                    _err <- KC.commitAllOffsets KC.OffsetCommit kafka
                    pure ()
          ) [0 :: Integer .. 10]
