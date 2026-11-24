import QtQuick
import Quickshell
import Quickshell.Hyprland
import "panels" as Panels
import "services" as Services
import "widgets" as Widgets
import "themes" as Themes

// The launcher remains a separate, keyboard-first floating library.
// The capsule is an always-visible, compact overlay. Neither reserves a bar.
ShellRoot {
    Panels.LauncherPanel { id: launcher }

    // One wallpaper service owns rotation, preferences and awww requests.
    Services.VerandaService {
        id: verandaService
        transitionLayer: vistaFx
    }
    Widgets.VistaTransition {
        id: vistaFx
        onSwapRequested: verandaService.transitionSwap()
        onAborted: function(reason) { verandaService.transitionAborted(reason); }
    }
    Panels.VerandaOfVistas {
        id: veranda
        wallpaperService: verandaService
    }

    // Celestial Gallery: separate illustrated panel and full-viewport viewer.
    // Intentionally not coupled to Veranda or the desktop wallpaper.
    Services.GalleryCatalogue {
        id: galleryCatalogue
        selectionLocked: celestialGallery.focusing || galleryViewer.phase !== "idle" || galleryEditor.opened
    }
    Panels.GalleryFullViewer {
        id: galleryViewer
        palette: Themes.Theme.current
        catalogue: galleryCatalogue
        editor: galleryEditor
    }
    Panels.CelestialGallery {
        id: celestialGallery
        viewer: galleryViewer
        catalogue: galleryCatalogue
        editor: galleryEditor
    }
    // One shared editor, opened from the Gallery and from the full viewer.
    Panels.GalleryCelestialEditor {
        id: galleryEditor
        catalogue: galleryCatalogue
        palette: Themes.Theme.current
    }

    Panels.ArchiveCapsule {
        id: capsule
        onVerandaRequested: {
            capsule.dismissPopups();
            veranda.toggleGallery();
        }
        onVerandaCloseRequested: veranda.closeGallery()
        onLauncherRequested: {
            if (!launcher.visible) launcher.openLauncher();
        }
        onWindowChooserRequested: function(appId) {
            // Reuse Batch 6's window chooser instead of implementing another.
            if (!launcher.visible) launcher.openLauncher();
            Qt.callLater(function() {
                if (launcher.visible) launcher.openWindowPicker(appId);
            });
        }
    }

    GlobalShortcut {
        name: "veranda-of-vistas"
        description: "Open or close the Veranda of Vistas wallpaper selector"
        onPressed: {
            capsule.dismissPopups();
            veranda.toggleGallery();
        }
    }

    GlobalShortcut {
        name: "celestial-gallery"
        description: "Show or hide the Celestial Gallery observatory"
        onPressed: {
            capsule.dismissPopups();
            celestialGallery.toggleGallery();
        }
    }

    GlobalShortcut {
        name: "astral-archive"
        description: "Open or close the Astral Archive launcher"
        onPressed: launcher.toggleLauncher()
    }
}
