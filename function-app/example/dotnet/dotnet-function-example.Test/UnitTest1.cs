using Xunit;
using Moq;
using dotnet_function_example;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;
using Microsoft.AspNetCore.Http.Internal;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;

namespace dotnet_function_example.Test
{
    public class UnitTest1
    {
        private static Mock<HttpRequest> CreateMockRequest()
        {
            var ms = new MemoryStream();

            ms.Position = 0;

            var mockRequest = new Mock<HttpRequest>();
            mockRequest.Setup(x => x.Body).Returns(ms);

            return mockRequest;
        }

        [Fact]
        public async Task ReturnSum()
        {
            Mock<HttpRequest> mockRequest = CreateMockRequest();
            var paramsDictionary = new Dictionary<string, StringValues>
            {
                { "x", "4" },
                { "y", "3" }
            };
            mockRequest.Setup(m => m.Query).Returns(new QueryCollection(paramsDictionary));

            IActionResult result = await Sum.Run(mockRequest.Object, new Mock<ILogger>().Object);
            var okResult = result as ObjectResult;
            Assert.Equal(7, okResult.Value);
        }
    }
}


