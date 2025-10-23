using System;
using System.Net.Http;
using System.Threading.Tasks;
using Xunit;

// Explicitly tell the compiler that "Assert" means xUnit's Assert
// (useful if other test frameworks are also referenced in the solution)
using Assert = Xunit.Assert;

namespace BucStop.UiTests.Smoke
{
    // A tiny "smoke" test: does the Games page load and contain the text "BucKart"?
    public class BucKart_HttpSmoke
    {
        // Base URL of the running web app.
        // Prefer BASE_URL env var (so CI and teammates can point to their own ports),
        // otherwise default to your local dev URL.
        private static readonly string BaseUrl =
            Environment.GetEnvironmentVariable("BASE_URL") ?? "https://localhost:7182"; // change if needed

        // Mark this as a single test case in xUnit.
        [Fact]
        public async Task GamesPage_Contains_BucKart_Text()
        {
            // Create an HttpClient that ignores local dev HTTPS certificate issues
            // so the test doesn't fail on self-signed/localhost certs.
            using var http = new HttpClient(new HttpClientHandler
            {
                ServerCertificateCustomValidationCallback = (_, __, ___, ____) => true
            });

            // Request the Games page (change "/" to "/games" if that's your list route)
            var resp = await http.GetAsync($"{BaseUrl}/");

            // Assert we got a successful HTTP status (e.g., 200 OK).
            // If not, include the actual status code in the failure message.
            Assert.True(resp.IsSuccessStatusCode, $"Expected 200 OK, got {(int)resp.StatusCode}.");

            // Read the HTML of the page as a string
            var html = await resp.Content.ReadAsStringAsync();

            // Assert that the HTML contains the text "BucKart".
            // This proves the new game appears alongside the others without relying on selectors/JS.
            Assert.Contains("BucKart", html);
        }
    }
}
