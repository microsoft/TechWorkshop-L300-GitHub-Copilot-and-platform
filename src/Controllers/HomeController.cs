using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ProductService _productService;
    private readonly CartService _cartService;
    private readonly ContentSafetyService _contentSafetyService;

    public HomeController(ILogger<HomeController> logger, ProductService productService, CartService cartService, ContentSafetyService contentSafetyService)
    {
        _logger = logger;
        _productService = productService;
        _cartService = cartService;
        _contentSafetyService = contentSafetyService;
    }

    private async Task<bool> IsUserInputSafeAsync(string userInput)
    {
        var (isSafe, log) = await _contentSafetyService.EvaluateTextAsync(userInput);
        if (!isSafe)
        {
            _logger.LogWarning("Blocked unsafe user input: {Log}", log);
        }
        return isSafe;
    }

    public IActionResult Index()
    {
        _logger.LogInformation("Loading products page");
        var products = _productService.GetAllProducts();
        return View(products);
    }

    [HttpPost]
    public IActionResult AddToCart(int productId)
    {
        var product = _productService.GetProductById(productId);
        if (product != null)
        {
            _logger.LogInformation("Adding product {ProductId} ({ProductName}) to cart", productId, product.Name);
            _cartService.AddToCart(productId);
        }
        else
        {
            _logger.LogWarning("Attempted to add non-existent product {ProductId} to cart", productId);
        }

        return RedirectToAction("Index");
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
