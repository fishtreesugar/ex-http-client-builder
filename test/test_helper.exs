# use --include httpbin to include it
ExUnit.configure(exclude: [httpbin: true])
ExUnit.start()
