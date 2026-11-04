# MediaPipe (used by flutter_gemma) references classes that are not packaged
# in the app: AutoValue's Memoized extension and unused protobuf types.
# R8 only needs to be told not to warn about them; they are never called
# on the code paths the app uses.
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.mediapipe.proto.**
