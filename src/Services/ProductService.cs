using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ProductService
    {
        private static readonly List<Product> _products = new List<Product>
        {
            new Product
            {
                Id = 1,
                Name = "Wireless Noise-Canceling Headphones",
                Description = "Over-ear Bluetooth headphones with active noise cancellation and 30-hour battery life.",
                Price = 199.99m,
                ImageUrl = "https://picsum.photos/id/1010/200/200"
            },
            new Product
            {
                Id = 2,
                Name = "Smart Fitness Watch",
                Description = "Tracks steps, heart rate, and sleep with a high-resolution AMOLED display.",
                Price = 149.95m,
                ImageUrl = "https://picsum.photos/id/1025/200/200"
            },
            new Product
            {
                Id = 3,
                Name = "4K Action Camera",
                Description = "Waterproof sports camera with 4K video recording and wide-angle lens.",
                Price = 129.50m,
                ImageUrl = "https://picsum.photos/id/1003/200/200"
            },
            new Product
            {
                Id = 4,
                Name = "Bluetooth Speaker",
                Description = "Portable waterproof Bluetooth speaker with deep bass and 12-hour playtime.",
                Price = 89.99m,
                ImageUrl = "https://picsum.photos/id/103/200/200"
            },
            new Product
            {
                Id = 5,
                Name = "Laptop Stand",
                Description = "Adjustable aluminum stand compatible with all MacBook and Windows laptops.",
                Price = 39.95m,
                ImageUrl = "https://picsum.photos/id/1050/200/200"
            },
            new Product
            {
                Id = 6,
                Name = "Mechanical Keyboard",
                Description = "RGB backlit mechanical keyboard with blue switches and detachable wrist rest.",
                Price = 99.00m,
                ImageUrl = "https://picsum.photos/id/1070/200/200"
            },
            new Product
            {
                Id = 7,
                Name = "Ergonomic Office Chair",
                Description = "High-back mesh chair with adjustable lumbar support and headrest.",
                Price = 249.00m,
                ImageUrl = "https://picsum.photos/id/1080/200/200"
            },
            new Product
            {
                Id = 8,
                Name = "USB-C Hub Docking Station",
                Description = "8-in-1 hub with HDMI, USB 3.0, SD card reader, and 100W PD charging.",
                Price = 59.99m,
                ImageUrl = "https://picsum.photos/id/109/200/200"
            },
            new Product
            {
                Id = 9,
                Name = "Smart LED Light Bulb",
                Description = "Wi-Fi enabled color-changing LED bulb compatible with Alexa and Google Home.",
                Price = 24.99m,
                ImageUrl = "https://picsum.photos/id/110/200/200"
            },
            new Product
            {
                Id = 10,
                Name = "Electric Standing Desk",
                Description = "Adjustable height desk with dual motors and memory presets.",
                Price = 499.00m,
                ImageUrl = "https://picsum.photos/id/111/200/200"
            }        
        };

        public List<Product> GetAllProducts()
        {
            return _products;
        }

        public Product? GetProductById(int id)
        {
            return _products.FirstOrDefault(p => p.Id == id);
        }
    }
}
