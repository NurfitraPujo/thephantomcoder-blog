---
layout: post
title: "Go Performance Deep Dive: Values vs. Pointers in Slices"
date: 2025-06-07 07:00:00 +0700
categories: updates
published: true
tags: ['golang', 'memory management', 'optimizing memory', 'golang performance', 'golang slices', 'golang performance']
description: |
  Go's simplicity and performance are two of its biggest strengths, but even experienced Gophers can sometimes scratch their heads over performance nuances. One common area of curiosity revolves around how we handle data in slices: should you store **values** directly or **pointers** to those values?
---

Go's simplicity and performance are two of its biggest strengths, but even experienced Gophers can sometimes scratch their heads over performance nuances. One common area of curiosity revolves around how we handle data in slices: should you store **values** directly or **pointers** to those values? While it might seem like a minor detail, the choice can significantly impact your application's CPU usage, memory allocation, and overall execution time.

In this deep dive, we'll unpack the practical implications of using slices of values versus slices of pointers in Go, backed by real-world performance considerations and benchmarking. By the end, you'll have a clearer understanding of when to choose one over the other to write more efficient Go code.

## Understanding the Basics: Values vs. Pointers

Before we dive into performance, let's quickly clarify what we mean by storing values or pointers in a slice.

### Slices of Values
When you create a slice of values (e.g., `[]MyStruct`), each element in the slice directly holds a copy of the data. This means that when you pass the slice around or modify an element, you're working with the actual data itself.

```go
type SmallStruct struct {
    ID    int
    Value int
}
func main() {
    // A slice of SmallStruct values
    values := []SmallStruct{
        {ID: 1, Value: 10},
        {ID: 2, Value: 20},
    }
    fmt.Println(values) // [{1 10} {2 20}]
}
```

### Slices of Pointers
In contrast, a slice of pointers (e.g., `[]*MyStruct`) stores memory addresses that point to where the actual data resides. When you access an element in such a slice, Go dereferences the pointer to retrieve the underlying data.

```go
type LargeStruct struct {
    Name  string
    Data  [1024]byte // A large array to simulate significant data
}

func main() {
    // A slice of pointers to LargeStruct
    ptrValues := []*LargeStruct{
        {Name: "Item A", Data: [1024]byte{}},
        {Name: "Item B", Data: [1024]byte{}},
    }
    fmt.Println(ptrValues[0].Name) // Item A
}
```

## The Performance Factors: CPU, Memory, and Time
Now that we've covered the basics, let's explore how these two approaches impact your application's performance.

### CPU Usage: The Cost of Copying and Cache Locality
**Copying Overhead**: When you're dealing with slices of values, especially if those values are large structs, every time an element is added, removed, or passed to a function, Go might need to copy the entire value. This copying can become a significant CPU overhead, especially in hot code paths.
 
**Cache Locality**: On the flip side, slices of values often offer better cache locality. This means that data elements are stored contiguously in memory. When your program accesses one element, there's a high probability that the next element it needs is already nearby in the CPU's cache, leading to faster access times. This is a big win for performance-critical applications that iterate over large datasets.

**Garbage Collection (GC) Overhead**: With slices of pointers, each pointer refers to a separate object allocated on the heap. This can lead to a greater number of distinct objects for Go's Garbage Collector (GC) to track and manage. While Go's GC is highly optimized, a larger number of objects can still introduce more work for the GC, potentially leading to slight pauses or increased CPU utilization during collection cycles.

### Memory Allocations: Heap vs. Stack and Footprint

**Contiguous Memory vs. Dispersed Objects**: A slice of values typically allocates a single, contiguous block of memory for all its elements (assuming they fit on the stack or are allocated as a single block on the heap). This can be efficient in terms of memory layout.

**Heap Allocations for Pointers**: For slices of pointers, the slice itself holds pointers, but the actual data pointed to by those pointers is typically allocated individually on the heap. This results in many small, separate allocations. While the slice of pointers itself might be smaller, the total memory footprint across all the scattered objects can be larger due to per-object overhead.

**Impact on Memory Locality**: The scattered nature of objects pointed to by a slice of pointers can negatively impact memory locality, making it harder for the CPU to predict and pre-fetch data into its cache.

### Time Taken: The Cumulative Effect
The ultimate measure of performance often comes down to execution time.

**Slices of values** can be faster for scenarios involving small data and frequent iterations due to their excellent cache locality and reduced GC pressure. The cost of copying small values is often less than the overhead of dereferencing pointers and managing more dispersed heap objects.

**Slices of pointers** become more efficient when dealing with very large data structures, as copying those large values would be prohibitively expensive. They also shine when you need to share a single instance of an object across different parts of your application without creating multiple copies. The trade-off is often increased GC activity and potentially poorer cache performance for sequential access.

## Impact on Developer Experience (DX)

Beyond raw performance numbers, the choice between values and pointers in slices also influences how easy your code is to write, read, debug, and maintain.

 * **Simplicity and Readability**:
   * Slices of values often lead to simpler, more straightforward code. You're working directly with the data, reducing the mental overhead of indirection. This can be particularly beneficial for Go newcomers.
   * Slices of pointers introduce an extra layer of indirection. While familiar to experienced developers, it can make the flow harder to trace for those less accustomed to pointer semantics.
 * **Mutability and Side Effects**:
   * When you pass a slice of values to a function or assign an element, you're usually working with a copy of the data. Modifications to that copy won't affect the original slice element unless you explicitly pass a pointer to the value. This can be safer by preventing unintended side effects.
   * With slices of pointers, all references point to the same underlying data. If one part of your program modifies the data through a pointer, that change is immediately visible to all other parts holding a pointer to the same object. This is powerful for sharing state but demands careful management to avoid unexpected mutations and hard-to-trace bugs.
 * **Handling nil Values**:
   * Slices of values do not inherently have nil elements (unless the zero value of the type itself is relevant, like a nil slice within a struct).
   * Slices of pointers can contain nil pointers. This means you often need to add nil checks before dereferencing a pointer, which adds boilerplate code and potential panic opportunities if forgotten.
 * **Initialization and Creation**:
   * Creating and populating slices of values can feel more natural as you directly assign the struct instances.
   * Populating slices of pointers often requires explicitly taking the address of a value (e.g., `&MyStruct{...}`) or using `new(MyStruct)` for each element, adding a slight syntactic overhead. 
   
In essence, while pointers offer flexibility and can be performance-critical for large data, values often provide a more "Go-idiomatic" and safer approach for smaller data, leading to cleaner code and fewer unexpected behaviors.

## Practical Examples & Benchmarking
The best way to understand the performance implications is to see them in action. We'll set up two benchmarking scenarios in Go: one with a small struct where values might shine, and another with a larger struct where pointers could offer benefits. Finally, we'll simulate a common real-world workflow: fetching data and marshalling it to JSON.

Remember, Go's testing package provides robust benchmarking tools. You can run these benchmarks in your terminal using `go test -bench=. -benchmem -count=5`.

```go
package main

import (
	"encoding/json" // Import the json package
	"fmt"
	"testing"
)

// SmallStruct represents a typical small data structure.
type SmallStruct struct {
	ID    int
	Value int
	Count int
}

// LargeStruct represents a larger data structure that might involve more copying.
// The [256]byte array is to simulate significant data.
type LargeStruct struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Data  [256]byte `json:"-"` // We won't marshal this large byte array to keep JSON small, but it contributes to struct size
	Value int    `json:"value"`
}

// simulateDBFetch simulates fetching a large number of LargeStructs from a database.
// This function itself is not benchmarked, but its output is used by the benchmarks.
func simulateDBFetch(count int) []LargeStruct {
	results := make([]LargeStruct, count)
	for i := 0; i < count; i++ {
		results[i] = LargeStruct{
			ID:    i,
			Name:  fmt.Sprintf("Product_%d", i),
			Value: i * 100,
			Data:  [256]byte{}, // Simulate some large internal data
		}
	}
	return results
}

// --- Scenario 1 Benchmarks: Small Structs ---

// BenchmarkSliceOfValues_SmallStruct benchmarks creating and iterating a slice of SmallStruct values.
func BenchmarkSliceOfValues_SmallStruct(b *testing.B) {
	size := 1000 // Number of elements in the slice
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Create the slice of values
		s := make([]SmallStruct, size)
		for j := 0; j < size; j++ {
			s[j] = SmallStruct{ID: j, Value: j * 10, Count: j % 5}
		}

		// Simulate iteration/access
		sum := 0
		for j := 0; j < size; j++ {
			sum += s[j].Value // Accessing the value directly
		}
		_ = sum // Prevent compiler optimization
	}
}

// BenchmarkSliceOfPointers_SmallStruct benchmarks creating and iterating a slice of SmallStruct pointers.
func BenchmarkSliceOfPointers_SmallStruct(b *testing.B) {
	size := 1000 // Number of elements in the slice
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Create the slice of pointers
		s := make([]*SmallStruct, size)
		for j := 0; j < size; j++ {
			s[j] = &SmallStruct{ID: j, Value: j * 10, Count: j % 5} // Allocate each struct on the heap
		}

		// Simulate iteration/access
		sum := 0
		for j := 0; j < size; j++ {
			sum += s[j].Value // Dereferencing the pointer to access the value
		}
		_ = sum // Prevent compiler optimization
	}
}

// --- Scenario 2 Benchmarks: Large Structs ---

// BenchmarkSliceOfValues_LargeStruct benchmarks creating and iterating a slice of LargeStruct values.
// This might be very memory intensive if 'size' is large.
func BenchmarkSliceOfValues_LargeStruct(b *testing.B) {
	size := 1000 // Number of elements in the slice
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Create the slice of values
		s := make([]LargeStruct, size)
		for j := 0; j < size; j++ {
			s[j] = LargeStruct{ID: j, Name: fmt.Sprintf("Item %d", j)} // Large structs are copied
		}

		// Simulate iteration/access
		sumID := 0
		for j := 0; j < size; j++ {
			sumID += s[j].ID
		}
		_ = sumID
	}
}

// BenchmarkSliceOfPointers_LargeStruct benchmarks creating and iterating a slice of LargeStruct pointers.
func BenchmarkSliceOfPointers_LargeStruct(b *testing.B) {
	size := 1000 // Number of elements in the slice
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Create the slice of pointers
		s := make([]*LargeStruct, size)
		for j := 0; j < size; j++ {
			s[j] = &LargeStruct{ID: j, Name: fmt.Sprintf("Item %d", j)} // Pointers are cheap to copy
		}

		// Simulate iteration/access
		sumID := 0
		for j := 0; j < size; j++ {
			sumID += s[j].ID // Dereferencing the pointer
		}
		_ = sumID
	}
}

// --- Scenario 3 Benchmarks: Real-World Workflow (DB to JSON) ---

// BenchmarkDBToValuesToJSON simulates fetching data, putting into []LargeStruct, and marshalling to JSON.
func BenchmarkDBToValuesToJSON(b *testing.B) {
	datasetSize := 1000 // Number of records to "fetch" and marshal
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// 1. Simulate DB fetch (returns slice of values)
		data := simulateDBFetch(datasetSize)

		// 2. Marshal the slice of values to JSON
		_, err := json.Marshal(data)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkDBToPointersToJSON simulates fetching data, converting to []*LargeStruct, and marshalling to JSON.
func BenchmarkDBToPointersToJSON(b *testing.B) {
	datasetSize := 1000 // Number of records to "fetch" and marshal
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// 1. Simulate DB fetch (returns slice of values)
		dataValues := simulateDBFetch(datasetSize)

		// 2. Convert to slice of pointers (this step adds overhead but is part of the pattern)
		dataPointers := make([]*LargeStruct, datasetSize)
		for j := 0; j < datasetSize; j++ {
			dataPointers[j] = &dataValues[j] // Take address of each value
		}

		// 3. Marshal the slice of pointers to JSON
		_, err := json.Marshal(dataPointers)
		if err != nil {
			b.Fatal(err)
		}
	}
}
```
### How to Run the Benchmarks:
 * Save the code above (including package main and import) into a file named main_test.go in a Go module.
 * Open your terminal in the same directory as the main_test.go file.
 * Run the command: go test -bench=. -benchmem -count=5
   * -bench=.: Runs all benchmark functions.
   * -benchmem: Shows memory allocation statistics.
   * -count=5: Runs each benchmark 5 times to get more stable results.
Analyze the ns/op (nanoseconds per operation), B/op (bytes allocated per operation), and allocs/op (allocations per operation) from the output to draw your conclusions.

## When to Use What: Making the Right Choice
As you've seen, there's no universal "better" option between slices of values and slices of pointers. The optimal choice depends heavily on your specific use case, the size and mutability of your data, and the overall performance characteristics you're optimizing for.
Here's a practical guide to help you decide:

**Use Slices of Values When:**
 * Your Structs Are Small and Fixed-Size: For structs that are a few words (e.g., int, string small enough to be inline, bool, or combinations thereof), the overhead of creating and managing pointers (and their associated heap allocations and GC pressure) often outweighs the cost of copying the value. Cache locality is a big win here.
 * Data Immutability is Desired or Modifications are Local: If your data structures are primarily read-only after creation, or if modifications to an element in the slice are intended to affect only that specific copy, values are safer and simpler. They prevent unintended side effects from shared references.
 * Simplicity and Readability are Key: For less complex scenarios, values keep your code straightforward and easier to reason about, especially for developers new to Go.
 * Minimizing Heap Allocations is Critical: If you're trying to reduce GC pauses and improve raw performance in highly sensitive loops, using values can significantly cut down on the number of individual heap allocations.

**Use Slices of Pointers When:**
 * Your Structs Are Large: If your structs contain large arrays, many fields, or other complex data structures, copying them repeatedly (e.g., when passing to functions or modifying) becomes very expensive in terms of CPU cycles and memory bandwidth. Using pointers avoids these large copies.
 * You Need to Share and Mutate the Same Instance: If multiple parts of your application need to refer to and potentially modify the exact same instance of an object (e.g., a shared configuration, a database connection pool item, or an object representing a unique entity), pointers are necessary.
 * Polymorphism is Required (Interfaces): When working with interfaces, you often need to store pointers to concrete types in a slice (e.g., []io.Reader) because methods on a concrete type that satisfy an interface are usually defined on the pointer receiver.
 * Reduced Slice Memory Footprint is a Priority (for the slice itself): While the total memory footprint might be higher due to dispersed objects, the slice itself (the list of pointers) is smaller than a list of large values, which can be relevant in certain memory-constrained scenarios or very large slices.
 * Nullability is a Feature: If it's valid for an element in your slice to explicitly represent "no object," pointers allow you to store nil. However, remember to handle nil checks carefully.

## Conclusion: Profile, Don't Guess

We've delved into the intricacies of slices of values versus slices of pointers in Go, examining their impact on CPU usage, memory allocations, execution time, and even developer experience.

The most important takeaway is this: there is no one-size-fits-all solution. Go provides powerful tools and flexibility, but with that comes the responsibility to understand the trade-offs.

 * For small, immutable data, slices of values often offer superior performance due to better cache locality and reduced GC overhead, alongside simpler code.

 * For large, mutable data, or when sharing single instances is critical, slices of pointers prevent expensive copying and enable shared state, though they introduce more heap allocations and pointer dereferencing costs.

Ultimately, the true performance characteristics of your application depend on your specific workload, data shapes, and access patterns. The best way to make an informed decision is to profile and benchmark your code with realistic data. Use Go's built-in pprof and testing packages to identify bottlenecks and validate your assumptions.

By understanding these fundamental differences and applying practical benchmarking, you can write more efficient, performant, and robust Go applications that truly leverage the language's strengths.