using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ASPNETCoreWebAPI;

public class ExceptionFilter : IExceptionFilter
{
    private readonly ILogger<ExceptionFilter> _logger;

    public ExceptionFilter(ILogger<ExceptionFilter> logger) =>
        _logger = logger;

    public void OnException(ExceptionContext context)
    {
        _logger.LogError(context.Exception, context.Exception.Message);

        context.ExceptionHandled = true;

        context.Result = new ContentResult
        {
            Content = context.Exception.Message,
            
        };
    }
}