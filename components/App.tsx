import { Routes, Route, Link, useLocation } from 'react-router-dom';
import Home from '../pages/Home';
import About from '../pages/About';
import Contact from '../pages/Contact';

function App() {
  const location = useLocation();
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <nav className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-4">
          <div className="flex justify-between items-center">
            <Link
              to="/"
              className="text-2xl font-bold text-blue-600"
            >
              React App
            </Link>
            <div className="space-x-4">
              <Link
                to="/"
                className={`text-gray-600 hover:text-blue-600 ${location.pathname === '/' ? 'text-blue-600' : ''}`}
              >
                Home
              </Link>
              <Link
                to="/about"
                className={`text-gray-600 hover:text-blue-600 ${location.pathname === '/about' ? 'text-blue-600' : ''}`}
              >
                About
              </Link>
              <Link
                to="/contact"
                className={`text-gray-600 hover:text-blue-600 ${location.pathname === '/contact' ? 'text-blue-600' : ''}`}
              >
                Contact
              </Link>
            </div>
          </div>
        </div>
      </nav>
      
      <main className="container mx-auto px-4 py-8">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/contact" element={<Contact />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;