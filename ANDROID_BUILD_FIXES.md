# Android Build Memory Optimization Fixes

## Problem
The Android build was failing with a Java heap space error during the desugaring process:
```
Execution failed for task ':app:desugarDebugFileDependencies'.
> Could not resolve all files for configuration ':app:debugRuntimeClasspath'.
   > Failed to transform x86_debug-1.0.0-72f2b18bb094f92f62a3113a8075240ebb59affa.jar
      > Java heap space
```

## Solutions Applied

### 1. Increased Java Heap Memory
- **File**: `android/gradle.properties`
- **Change**: Increased heap size from 4GB to 8GB
- **Change**: Increased MaxMetaspaceSize from 512MB to 1GB
- **Added**: Parallel GC optimization flags

```properties
org.gradle.jvmargs=-Xmx8g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError -XX:+UseParallelGC -XX:MaxGCPauseMillis=200 -Dfile.encoding=UTF-8
```

### 2. Added Build Performance Optimizations
- **File**: `android/gradle.properties`
- **Added**: Worker thread limit to prevent memory overload
- **Added**: R8 and D8 optimization flags

```properties
org.gradle.workers.max=4
android.enableR8.fullMode=false
android.enableD8.desugaring=true
android.enableD8.desugaring.artifacts=true
```

### 3. Enhanced App-Level Build Configuration
- **File**: `android/app/build.gradle`
- **Added**: DEX options with memory optimization
- **Added**: Disabled pre-dexing to reduce memory usage

```gradle
dexOptions {
    javaMaxHeapSize "4g"
    preDexLibraries = false
}
```

### 4. Updated CI/CD Configuration
- **File**: `codemagic.yaml`
- **Increased**: Build duration limits from 60 to 120 minutes
- **Added**: Memory optimization environment variables for all build workflows

```yaml
export GRADLE_OPTS="-Xmx8g -XX:MaxMetaspaceSize=1g -XX:+UseParallelGC"
```

### 5. Created Local Build Script
- **File**: `build_android.sh`
- **Purpose**: Provides memory-optimized local build process
- **Usage**: `./build_android.sh`

## How to Use

### For Local Development
1. Use the provided build script:
   ```bash
   ./build_android.sh
   ```

2. Or manually set environment variables:
   ```bash
   export GRADLE_OPTS="-Xmx8g -XX:MaxMetaspaceSize=1g -XX:+UseParallelGC"
   flutter build apk --debug
   ```

### For CI/CD
The `codemagic.yaml` file has been updated with memory optimization for all build workflows.

## Additional Recommendations

1. **Clean builds regularly**: Run `flutter clean` before builds
2. **Monitor memory usage**: Use `flutter doctor -v` to check system resources
3. **Update Flutter**: Ensure you're using the latest stable Flutter version
4. **Consider build variants**: Use specific build types to reduce memory usage

## Troubleshooting

If you still encounter memory issues:

1. **Increase heap size further**: Modify `-Xmx8g` to `-Xmx12g` in `gradle.properties`
2. **Reduce parallel workers**: Change `org.gradle.workers.max=4` to `org.gradle.workers.max=2`
3. **Disable parallel builds**: Set `org.gradle.parallel=false` temporarily
4. **Check system resources**: Ensure your build machine has sufficient RAM (recommended: 16GB+)

## Files Modified
- `android/gradle.properties`
- `android/app/build.gradle`
- `android/build.gradle`
- `codemagic.yaml`
- `build_android.sh` (new)