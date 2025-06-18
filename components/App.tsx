import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Home from '../pages/Home';
import About from '../pages/About';

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <nav className="bg-white shadow-md">
          <div className="container mx-auto px-4 py-4">
            <div className="flex justify-between items-center">
              <Link to="/" className="text-2xl font-bold text-blue-600">React App</Link>
              <div className="space-x-4">
                <Link to="/" className="text-gray-600 hover:text-blue-600 transition-colors">Home</Link>
                <Link to="/about" className="text-gray-600 hover:text-blue-600 transition-colors">About</Link>
              </div>
            </div>
          </div>
        </nav>
        
        <main>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/about" element={<About />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App; 